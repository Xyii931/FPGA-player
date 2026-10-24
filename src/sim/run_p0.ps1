# One invocation, one ModelSim process per case; preserve every case's result.
[CmdletBinding()]
param(
    [string]$VsimPath = 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe',
    [ValidateSet('P0', 'Media', 'Storage', 'All')]
    [string]$Suite = 'P0'
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
if ($Suite -eq 'Media' -or $Suite -eq 'All') { $cases += @('osd_fonts', 'osd_text_store', 'osd_text_video') }
$results = @()
Push-Location -LiteralPath $repoDir
try {
    foreach ($caseName in $cases) {
        $consoleLog = Join-Path $resultDir "$caseName-console.log"
        $stderrLog = Join-Path $resultDir "$caseName-stderr.log"
        $caseLog = Join-Path $simDir "build/$caseName/$caseName.log"
        $started = Get-Date
        $exitCode = -1
        $errorText = $null
        Write-Host "Running $caseName ..."
        try {
            # Relative path is ASCII; Tcl file joins inside each script handle repo spaces.
            # Keep native stderr separate: Windows PowerShell must not convert a
            # tool's diagnostic line into a terminating PowerShell exception.
            $process = Start-Process -FilePath $VsimPath -WorkingDirectory $repoDir `
                -ArgumentList @('-c', '-do', "`"do src/sim/run_$caseName.do`"") `
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
    ConvertTo-Json -InputObject @($results) -Depth 3 |
        Set-Content -LiteralPath (Join-Path $resultDir 'summary.json') -Encoding UTF8
}
$results | Format-Table Case, Passed, ExitCode, Seconds -AutoSize
Write-Host "Results: $resultDir"
if (@($results | Where-Object { -not $_.Passed }).Count -gt 0) { exit 1 }
exit 0
