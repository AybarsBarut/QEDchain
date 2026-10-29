. "$PSScriptRoot\common.ps1"
& alr -n build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
