. "$PSScriptRoot\common.ps1"
& "$PSScriptRoot\build.ps1"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& "$ProjectRoot\bin\test_runner.exe"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& "$ProjectRoot\tests\cli_tests.ps1"
exit 0
