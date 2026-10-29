$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$alrCommand = Get-Command alr -ErrorAction SilentlyContinue
if (-not $alrCommand) {
    $installedAlr = Join-Path $env:ProgramFiles 'Alire\bin'
    if (Test-Path (Join-Path $installedAlr 'alr.exe')) {
        $env:PATH = "$installedAlr;$env:PATH"
    } else { throw 'Install Alire and add alr to PATH.' }
}
Set-Location $ProjectRoot
