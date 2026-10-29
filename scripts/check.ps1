. "$PSScriptRoot\common.ps1"
& "$PSScriptRoot\test.ps1"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& "$PSScriptRoot\prove.ps1"
exit $LASTEXITCODE
