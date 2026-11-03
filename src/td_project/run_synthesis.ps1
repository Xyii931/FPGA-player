[CmdletBinding()]
param(
    [ValidateSet('lean_player')]
    [string]$Project = 'lean_player',
    [switch]$PlaceAndRoute,
    [string]$TdPath = 'D:/Anlogic/TD_6.2.1_Engineer_6.2.168.116/bin/td_commands_prompt.exe'
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $TdPath -PathType Leaf)) {
    throw "TD command-line executable not found: $TdPath. Set -TdPath."
}
$repoDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$runId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$runName = $Project
$relativeDir = ".local/td-build/$Project/$runId"
$resultDir = Join-Path $repoDir $relativeDir
New-Item -ItemType Directory -Path $resultDir -Force | Out-Null
$substDrive = $null
$simRepoDir = $repoDir
$previousProject = $env:FPGA_PLAYER_PROJECT
$previousPlaceRoute = $env:FPGA_PLAYER_PLACE_ROUTE
$exitCode = -1
$errorText = $null
$started = Get-Date
try {
    if ($repoDir -match '[^\x00-\x7F]') {
        foreach ($driveCode in (90..69)) {
            $candidateDrive = ([char]$driveCode).ToString()
            if (-not (Get-PSDrive -Name $candidateDrive -ErrorAction SilentlyContinue) -and
                -not (Test-Path -LiteralPath ($candidateDrive + ':\'))) {
                # A concurrent simulation can claim the probed letter first.
                # Retry without deleting a mapping owned by the other process.
                $candidateAlias = $candidateDrive + ':'
                $aliasOutput = & subst.exe $candidateAlias $repoDir 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $substDrive = $candidateAlias
                    break
                }
            }
        }
        if (-not $substDrive) { throw 'No free drive letter for the TD ASCII path alias.' }
        $simRepoDir = $substDrive + '\'
    }
    $env:FPGA_PLAYER_PROJECT = $Project
    $env:FPGA_PLAYER_PLACE_ROUTE = if ($PlaceAndRoute) { '1' } else { '0' }
    $scriptPath = (Join-Path $simRepoDir 'src/td_project/synthesize.tcl').Replace('\', '/')
    Write-Host "Synthesizing $runName ..."
    $process = Start-Process -FilePath $TdPath -WorkingDirectory (Join-Path $simRepoDir $relativeDir) `
        -ArgumentList @('"' + $scriptPath + '"') -WindowStyle Hidden -Wait -PassThru `
        -RedirectStandardOutput (Join-Path $resultDir 'console.log') `
        -RedirectStandardError (Join-Path $resultDir 'stderr.log')
    $exitCode = $process.ExitCode
} catch {
    $errorText = $_.Exception.Message
} finally {
    $env:FPGA_PLAYER_PROJECT = $previousProject
    $env:FPGA_PLAYER_PLACE_ROUTE = $previousPlaceRoute
    if ($substDrive) { & subst.exe $substDrive /D }
}
$consoleLog = Join-Path $resultDir 'console.log'
$synthesisComplete = (Test-Path -LiteralPath $consoleLog) -and
    (Select-String -LiteralPath $consoleLog -SimpleMatch "PLAYER_TD_SYNTH_PASS $runName" -Quiet)
$routeComplete = (Test-Path -LiteralPath $consoleLog) -and
    (Select-String -LiteralPath $consoleLog -SimpleMatch "PLAYER_TD_ROUTE_PASS $runName" -Quiet)
$completedStage = if ($routeComplete) { 'Routed' } elseif (
    Test-Path -LiteralPath (Join-Path $resultDir "${runName}_place.db")
) { 'Placed' } elseif ($synthesisComplete) { 'Synthesis' } else { 'Incomplete' }
$criticalWarnings = 0
$errors = 0
$resources = @()
$reportStage = if ($PlaceAndRoute) { 'phy' } else { 'gate' }
$areaReport = Join-Path $resultDir "${runName}_${reportStage}.area"
if (Test-Path -LiteralPath $areaReport) {
    foreach ($line in Get-Content -LiteralPath $areaReport) {
        if ($line -match '^\s*#(?<Name>[A-Za-z0-9_]+)\s+(?<Used>\d+)\s+out of\s+(?<Available>\d+)') {
            $resources += [pscustomobject]@{
                Name = $Matches.Name
                Used = [long]$Matches.Used
                Available = [long]$Matches.Available
            }
        }
    }
}
$resourceFits = @($resources | Where-Object { $_.Name -eq 'lut' }).Count -eq 1 -and
    @($resources | Where-Object { $_.Name -eq 'reg' }).Count -eq 1 -and
    @($resources | Where-Object { $_.Used -gt $_.Available }).Count -eq 0
if (Test-Path -LiteralPath $consoleLog) {
    $criticalWarnings = @(Select-String -LiteralPath $consoleLog -Pattern ' CRITICAL-WARNING:').Count
    $errors = @(Select-String -LiteralPath $consoleLog -Pattern ' ERROR:').Count
}
$passed = $exitCode -eq 0 -and $synthesisComplete -and
    $resourceFits -and
    $criticalWarnings -eq 0 -and $errors -eq 0
if ($PlaceAndRoute) {
    $passed = $passed -and $routeComplete
}
$setupWns = $null
$holdWns = $null
$timingMet = $null
$timingStatus = Join-Path $resultDir "${runName}_${reportStage}.ts"
if (Test-Path -LiteralPath $timingStatus) {
    $timingText = Get-Content -LiteralPath $timingStatus -Raw
    if ($timingText -match 'SWNS:\s*(-?\d+(?:\.\d+)?)ns') {
        $setupWns = [double]::Parse($Matches[1], [System.Globalization.CultureInfo]::InvariantCulture)
    }
    if ($timingText -match 'HWNS:\s*(-?\d+(?:\.\d+)?)ns') {
        $holdWns = [double]::Parse($Matches[1], [System.Globalization.CultureInfo]::InvariantCulture)
    }
    if ($null -ne $setupWns -and $null -ne $holdWns) {
        $timingMet = $setupWns -ge 0 -and $holdWns -ge 0
    }
}
if ($PlaceAndRoute) { $passed = $passed -and $timingMet -eq $true }
$result = [pscustomobject]@{
    Project = $Project
    Stage = $completedStage
    RequestedStage = if ($PlaceAndRoute) { 'Routed' } else { 'Synthesis' }
    Passed = [bool]$passed
    ExitCode = $exitCode
    CriticalWarnings = $criticalWarnings
    Errors = $errors
    ResourceFits = [bool]$resourceFits
    Resources = @($resources)
    SetupWnsNs = $setupWns
    HoldWnsNs = $holdWns
    TimingMet = $timingMet
    Seconds = [math]::Round(((Get-Date) - $started).TotalSeconds, 2)
    ConsoleLog = $consoleLog
    StderrLog = Join-Path $resultDir 'stderr.log'
    Error = $errorText
}
$result | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $resultDir 'summary.json') -Encoding UTF8
$result | Format-List
Write-Host "Results: $resultDir"
if ($timingMet -eq $false) { Write-Host "Timing target not met; inspect ${reportStage}.ts and timing reports." }
if (-not $passed) { exit 1 }
exit 0
