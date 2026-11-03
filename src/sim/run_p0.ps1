# One invocation, one ModelSim process per case; preserve every case's result.
[CmdletBinding()]
param(
    [string]$VsimPath = 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe',
    [ValidateSet('P0', 'Media', 'Storage', 'Lean', 'All')]
    [string]$Suite = 'Lean',
    [string[]]$Case = @(),
    [switch]$NoVopt
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $VsimPath -PathType Leaf)) {
    throw "ModelSim executable not found: $VsimPath. Set -VsimPath to your vsim.exe."
}
$simDir = $PSScriptRoot
$repoDir = Split-Path (Split-Path $simDir -Parent) -Parent
$runId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$resultDir = Join-Path $simDir "build/$($Suite.ToLowerInvariant())/$runId"
New-Item -ItemType Directory -Path $resultDir -Force | Out-Null
$suites = [ordered]@{
    P0 = @('reset_sync', 'reset_gen', 'pll_tree', 'video_pattern_axis')
    Storage = @('spi_byte_master', 'sd_spi_phy', 'sd_csd_decode', 'sd_sector_reader',
        'sector_cdc_bridge', 'fat32_mount', 'fat32_chain_walk', 'fat32_file_reader', 'native_sdram_ctrl', 'scan_chain')
    Media = @('bmp_parser', 'wav_parser', 'async_fifo', 'audio_frame_fifo')
    Lean = @('lean_media_source', 'lean_player_ctrl', 'lean_image_loader',
        'lean_video', 'lean_audio', 'lean_audio_cache', 'lean_player_core')
}
$cases = if ($Suite -eq 'All') {
    @($suites.Values | ForEach-Object { $_ } | Select-Object -Unique)
} else {
    @($suites[$Suite])
}
if ($Case.Count -gt 0) {
    foreach ($requestedCase in $Case) {
        if ($cases -notcontains $requestedCase) {
            throw "Case '$requestedCase' is not part of suite '$Suite'."
        }
    }
    $cases = @($Case | Select-Object -Unique)
}
$results = @()
$substDrive = $null
$simRepoDir = $repoDir
Push-Location -LiteralPath $repoDir
try {
    # ModelSim 10.3c cannot reliably create its work database under Unicode paths.
    # A temporary drive alias keeps files in this checkout without copying them.
    if ($repoDir -match '[^\x00-\x7F]') {
        foreach ($driveCode in (90..69)) {
            $candidateDrive = ([char]$driveCode).ToString()
            if (-not (Get-PSDrive -Name $candidateDrive -ErrorAction SilentlyContinue) -and
                -not (Test-Path -LiteralPath ($candidateDrive + ':\'))) {
                # Another verification process may claim this letter after the
                # probe. Only own a mapping after subst succeeds; otherwise retry.
                $candidateAlias = $candidateDrive + ':'
                $aliasOutput = & subst.exe $candidateAlias $repoDir 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $substDrive = $candidateAlias
                    break
                }
            }
        }
        if (-not $substDrive) { throw 'No free drive letter for the ModelSim ASCII path alias.' }
        $simRepoDir = $substDrive + '\'
    }
    foreach ($caseName in $cases) {
        $consoleLog = Join-Path $resultDir "$caseName-console.log"
        $stderrLog = Join-Path $resultDir "$caseName-stderr.log"
        $startupLog = "src/sim/build/$($Suite.ToLowerInvariant())/$runId/$caseName-startup.log"
        $caseLog = Join-Path $simDir "build/$caseName/$caseName.log"
        $started = Get-Date
        $exitCode = -1
        $errorText = $null
        $wrapperPath = Join-Path $simDir ".runner_${caseName}_$runId.wrap.do"
        $caseRunnerPath = Join-Path $simDir ".runner_${caseName}_$runId.do"
        $sourceRel = "src/sim/run_$caseName.do"
        Write-Host "Running $caseName ..."
        try {
            if ($NoVopt) {
                # ModelSim 10.1c hangs in its automatic vopt step; -novopt runs.
                $caseText = Get-Content -LiteralPath (Join-Path $simDir "run_$caseName.do") -Raw
                $caseText = $caseText.Replace('-voptargs=+acc', '-novopt')
                Set-Content -LiteralPath $caseRunnerPath -Value $caseText -NoNewline -Encoding ASCII
                $sourceRel = "src/sim/.runner_${caseName}_$runId.do"
            }
            # A wrapper file keeps vsim's -do command to a simple `source`.
            # ModelSim 10.1c rejects the inline catch/source command.
            $wrapperLines = @(
                ('if {[catch {source "' + $sourceRel + '"} detail]} {'),
                '    puts stderr $detail',
                '    quit -force -code 1',
                '}'
            )
            Set-Content -LiteralPath $wrapperPath -Value $wrapperLines -Encoding ASCII
            $simCommand = "source src/sim/.runner_${caseName}_$runId.wrap.do"
            # Keep native stderr separate: Windows PowerShell must not convert a
            # tool's diagnostic line into a terminating PowerShell exception.
            $process = Start-Process -FilePath $VsimPath -WorkingDirectory $simRepoDir `
                -ArgumentList @('-c', '-l', $startupLog, '-do', ('"' + $simCommand + '"')) `
                -WindowStyle Hidden -Wait -PassThru `
                -RedirectStandardOutput $consoleLog -RedirectStandardError $stderrLog
            $exitCode = $process.ExitCode
        } catch {
            $errorText = $_.Exception.Message
            Add-Content -LiteralPath $consoleLog -Value $errorText
        } finally {
            Remove-Item -LiteralPath $caseRunnerPath, $wrapperPath -Force -ErrorAction SilentlyContinue
        }
        $archivedLog = $null
        $transcriptFresh = $false
        # Do not attach a stale transcript from a previous run if startup failed.
        if (Test-Path -LiteralPath $caseLog) {
            if ((Get-Item -LiteralPath $caseLog).LastWriteTime -ge $started) {
                $archivedLog = Join-Path $resultDir "$caseName.log"
                Copy-Item -LiteralPath $caseLog -Destination $archivedLog
                $transcriptFresh = $true
            }
        }
        $hasPass = $false
        $harnessFailure = $false
        if ($transcriptFresh) {
            $hasPass = Select-String -LiteralPath $caseLog -Pattern '^#\s*PASS' -Quiet
            $harnessFailure = Select-String -LiteralPath $caseLog -Quiet -Pattern `
                'Startup command is not a complete Tcl command|syntax error|Failed to find design unit|Error loading design'
        }
        if ($null -eq $errorText -and $exitCode -ne 0) { $errorText = "vsim exited with code $exitCode" }
        if ($null -eq $errorText -and -not $transcriptFresh) { $errorText = 'Transcript missing or not refreshed by this run' }
        if ($null -eq $errorText -and -not $hasPass) { $errorText = 'Transcript has no PASS marker' }
        if ($null -eq $errorText -and $harnessFailure) { $errorText = 'Transcript contains a harness error' }
        $casePassed = ($exitCode -eq 0) -and $transcriptFresh -and $hasPass -and (-not $harnessFailure)
        $results += [pscustomobject]@{
            Case = $caseName
            Passed = $casePassed
            ExitCode = $exitCode
            Seconds = [math]::Round(((Get-Date) - $started).TotalSeconds, 2)
            Transcript = $archivedLog
            ConsoleLog = $consoleLog
            StderrLog = $stderrLog
            NoVopt = [bool]$NoVopt
            Error = $errorText
        }
    }
} finally {
    Pop-Location
    if ($substDrive) { & subst.exe $substDrive /D }
    ConvertTo-Json -InputObject @($results) -Depth 3 |
        Set-Content -LiteralPath (Join-Path $resultDir 'summary.json') -Encoding UTF8
}
$results | Format-Table Case, Passed, ExitCode, Seconds -AutoSize
Write-Host "Results: $resultDir"
if (@($results | Where-Object { -not $_.Passed }).Count -gt 0) { exit 1 }
exit 0
