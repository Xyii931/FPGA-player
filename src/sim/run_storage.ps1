[CmdletBinding()]
param(
    [string]$VsimPath = 'D:/altera/14.1/modelsim_ase/win32aloem/vsim.exe'
)
& (Join-Path $PSScriptRoot 'run_p0.ps1') -VsimPath $VsimPath -Suite Storage
exit $LASTEXITCODE
