# One invocation, one ModelSim process per case; preserve every case's result.
[CmdletBinding()]
param(
    [string]$VsimPath = 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe',
    [ValidateSet('P0', 'Media', 'Storage', 'All')]
    [string]$Suite = 'P0',
    [string[]]$Case = @()
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
$cases = @('reset_sync', 'reset_gen', 'pll_tree', 'clk_monitor', 'p0_video_source', 'video_pattern_axis')
if ($Suite -eq 'Storage') { $cases = @('spi_byte_master', 'sd_spi_phy', 'sd_csd_decode', 'sd_sector_reader', 'sector_cdc_bridge', 'fat32_mount', 'fat32_chain_walk', 'fat32_file_reader', 'fat32_dir_parser', 'fat32_directory', 'fat32_path_lookup', 'fat32_sector_arbiter', 'fat32_core', 'media_file_service', 'frame_memory') }
if ($Suite -eq 'Media') { $cases = @('bmp_parser', 'bmp_file_source', 'bmp_file_fat32', 'image_scaler', 'bmp_image_scaler', 'image_geometry', 'image_transform', 'fb_slot_manager', 'display_lease_ctrl', 'display_source_guard', 'fb_writer', 'image_transform_writer', 'bmp_frame_load_ctrl', 'bmp_frame_loader', 'fb_line_reader', 'fb_reader', 'frame_commit_cdc', 'display_commit', 'display_candidate_ctrl', 'display_reader_arbiter', 'display_video_pipeline', 'display_host_owner', 'display_lease_cdc', 'display_lease_cdc_host', 'display_resource_pipeline', 'display_deadline_cdc', 'display_deadline_scheduler', 'display_timed_pipeline', 'display_target_scheduler', 'display_target_pipeline', 'display_event_executor', 'av_timeline_display', 'playback_transition_owner', 'playback_transition_display', 'image_reservation_cdc', 'image_load_reservation', 'playback_image_ctrl', 'playback_image_display', 'image_load_owner', 'image_load_pipeline', 'transition_pixel', 'blend_unit', 'scanout_engine', 'audio_foundation', 'wav_parser', 'async_fifo', 'audio_frame_fifo', 'audio_track_guard', 'audio_mix', 'audio_playback', 'wav_track_source', 'wav_file_source', 'wav_file_fat32', 'audio_slot_recycle', 'wav_audio_player', 'audio_prepare_guard', 'display_audio_pipeline', 'av_event_timeline', 'av_timeline_wav', 'playlist_parser', 'media_index_store', 'playlist_index_builder', 'playlist_file_source', 'playlist_file_fat32', 'directory_index_source', 'directory_index_fat32', 'media_scan_ctrl', 'media_index_scan_fat32', 'player_av_core') }
if ($Suite -eq 'All') { $cases += @('bmp_parser', 'bmp_file_source', 'bmp_file_fat32', 'image_scaler', 'bmp_image_scaler', 'image_geometry', 'image_transform', 'fb_slot_manager', 'display_lease_ctrl', 'display_source_guard', 'fb_writer', 'image_transform_writer', 'bmp_frame_load_ctrl', 'bmp_frame_loader', 'fb_line_reader', 'fb_reader', 'frame_commit_cdc', 'display_commit', 'display_candidate_ctrl', 'display_reader_arbiter', 'display_video_pipeline', 'display_host_owner', 'display_lease_cdc', 'display_lease_cdc_host', 'display_resource_pipeline', 'display_deadline_cdc', 'display_deadline_scheduler', 'display_timed_pipeline', 'display_target_scheduler', 'display_target_pipeline', 'display_event_executor', 'av_timeline_display', 'playback_transition_owner', 'playback_transition_display', 'image_reservation_cdc', 'image_load_reservation', 'playback_image_ctrl', 'playback_image_display', 'image_load_owner', 'image_load_pipeline', 'transition_pixel', 'blend_unit', 'scanout_engine', 'audio_foundation', 'wav_parser', 'async_fifo', 'audio_frame_fifo', 'audio_track_guard', 'audio_mix', 'audio_playback', 'wav_track_source', 'wav_file_source', 'wav_file_fat32', 'audio_slot_recycle', 'wav_audio_player', 'audio_prepare_guard', 'display_audio_pipeline', 'av_event_timeline', 'av_timeline_wav', 'playlist_parser', 'media_index_store', 'playlist_index_builder', 'playlist_file_source', 'playlist_file_fat32', 'directory_index_source', 'directory_index_fat32', 'media_scan_ctrl', 'media_index_scan_fat32', 'player_av_core') }
if ($Suite -eq 'All') { $cases += @('spi_byte_master', 'sd_spi_phy', 'sd_csd_decode', 'sd_sector_reader', 'sector_cdc_bridge', 'fat32_mount', 'fat32_chain_walk', 'fat32_file_reader', 'fat32_dir_parser', 'fat32_directory', 'fat32_path_lookup', 'fat32_sector_arbiter', 'fat32_core', 'media_file_service', 'frame_memory') }
if ($Suite -eq 'Media' -or $Suite -eq 'All') { $cases += @('player_board', 'player_console', 'playlist_policy', 'player_audio_policy', 'player_layout', 'audio_file_decoder', 'image_file_decoder', 'resident_frame', 'demo_media', 'raw_recovery') }
if ($Suite -eq 'Storage' -or $Suite -eq 'All') { $cases += @('player_settings') }
if ($Suite -eq 'Media' -or $Suite -eq 'All') { $cases += @('osd_fonts', 'osd_text_store', 'osd_text_video', 'osd_menu_builder') }
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
        Write-Host "Running $caseName ..."
        try {
            # Tcl source sets [info script] correctly; ModelSim do does not.
            # Catch source errors explicitly: onerror only handles ModelSim macros.
            $simCommand = 'if {[catch {source src/sim/run_' + $caseName +
                '.do} detail]} {puts stderr $detail; quit -force -code 1}'
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
        }
        $archivedLog = $null
        # Do not attach a stale transcript from a previous run if startup failed.
        if (Test-Path -LiteralPath $caseLog) {
            if ((Get-Item -LiteralPath $caseLog).LastWriteTime -ge $started) {
                $archivedLog = Join-Path $resultDir "$caseName.log"
                Copy-Item -LiteralPath $caseLog -Destination $archivedLog
            }
        }
        $results += [pscustomobject]@{
            Case = $caseName
            Passed = ($exitCode -eq 0)
            ExitCode = $exitCode
            Seconds = [math]::Round(((Get-Date) - $started).TotalSeconds, 2)
            Transcript = $archivedLog
            ConsoleLog = $consoleLog
            StderrLog = $stderrLog
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
