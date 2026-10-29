. "$PSScriptRoot\common.ps1"
New-Item -ItemType Directory -Force (Join-Path $ProjectRoot 'docs') | Out-Null
$log = Join-Path $ProjectRoot 'docs\gnatprove.log'
$report = Join-Path $ProjectRoot 'obj\gnatprove\gnatprove.out'
if (Test-Path $report) { Remove-Item -LiteralPath $report }
$units = @(Get-ChildItem (Join-Path $ProjectRoot 'src') -Filter '*.ad?' | ForEach-Object { $_.Name })
$arguments = @('-n', 'exec', '--', 'gnatprove', '-P', 'chainguard.gpr', '-u') + $units + @('--level=2', '--mode=all', '--report=all', '--checks-as-errors=on')
$stdout = Join-Path $ProjectRoot 'docs\gnatprove.stdout.log'
$stderr = Join-Path $ProjectRoot 'docs\gnatprove.stderr.log'
$process = Start-Process -FilePath (Get-Command alr).Source -ArgumentList $arguments -WorkingDirectory $ProjectRoot -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$proofExit = $process.ExitCode
$raw = [IO.File]::ReadAllText($stdout) + [IO.File]::ReadAllText($stderr)
[IO.File]::WriteAllText($log, $raw)
Write-Output $raw
$content = if (Test-Path $report) { Get-Content $report -Raw } else { 'No GNATprove summary was produced.' }
if (-not (Test-Path $report)) { $proofExit = 1 }
$table = @('| Package | Total checks | Proved | Unproved |', '|---|---:|---:|---:|')
$residual = @()
$totalChecks = 0
$totalProved = 0
$forbidden = 0
foreach ($spec in Get-ChildItem (Join-Path $ProjectRoot 'src') -Filter '*.ads' | Sort-Object Name) {
    $dataPath = Join-Path $ProjectRoot ("obj\gnatprove\" + $spec.BaseName + '.spark')
    if (-not (Test-Path $dataPath)) {
        $residual += "Missing analysis data: $($spec.Name)"
        $proofExit = 1
        continue
    }
    $data = Get-Content $dataPath -Raw | ConvertFrom-Json
    $entries = @($data.flow) + @($data.proof)
    $proved = @($entries | Where-Object { $_.severity -eq 'info' -and $_.how_proved -ne 'justified' }).Count
    $unproved = $entries.Count - $proved
    $table += "| $($spec.BaseName) | $($entries.Count) | $proved | $unproved |"
    $totalChecks += $entries.Count
    $totalProved += $proved
    $forbidden += @($data.pragma_assume).Count + @($data.skip_proof).Count + @($data.skip_flow_proof).Count
    foreach ($entry in $entries | Where-Object { $_.severity -ne 'info' -or $_.how_proved -eq 'justified' }) {
        $residual += "$($entry.file):$($entry.line): $($entry.message.text)"
    }
}
$remaining = $totalChecks - $totalProved
$table += "| **Total** | **$totalChecks** | **$totalProved** | **$remaining** |"
if ($remaining -ne 0 -or $forbidden -ne 0 -or $totalChecks -eq 0) { $proofExit = 1 }
$versions = @(& alr --version) + @(& alr -n exec -- gnatprove --version)
$fingerprints = @('| Source | SHA-256 |', '|---|---|')
$proofFiles = @(Get-ChildItem (Join-Path $ProjectRoot 'src') -File) + @(Get-Item "$ProjectRoot\chainguard.gpr", "$ProjectRoot\alire.toml")
foreach ($file in $proofFiles | Sort-Object Name) {
    $fingerprints += "| $($file.Name) | $((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLower()) |"
}
$lines = @('# ChainGuard proof report', '', "Generated (UTC): $([DateTime]::UtcNow.ToString('u'))", '', ('Command: `alr ' + ($arguments -join ' ') + '`'), '', "Process/gate exit code: $proofExit", '', '## Package checks', '') + $table + @('', 'Counts include flow checks and prover checks. Zero-check specification units are still analyzed.', '', "Assumptions or skipped-analysis entries: $forbidden", '', '## Residual unproved checks', '')
if ($residual.Count -eq 0 -and $proofExit -eq 0) { $lines += 'None.' } else { $lines += $residual; $lines += 'See gnatprove.log for process diagnostics.' }
$lines += @('', '## Proof scope', '', 'Silver: all library packages. Gold: block/link/genesis definitions, index induction, Append preservation, verification equivalence and sampling bounds/state transition. Payload_Tamper_Lemma proves only a conditional statement whose explicit premise is that the two computed hashes differ. SHA-256 functional correctness and collision resistance are not proved. CLI file I/O and the test harness are outside SPARK analysis.', '', '## Toolchain', '', '```text') + $versions + @('```', '', '## Raw GNATprove summary', '', '```text', $content, '```', '', '## Source fingerprints', '') + $fingerprints
[IO.File]::WriteAllLines((Join-Path $ProjectRoot 'docs\PROOF_REPORT.md'), $lines)
Write-Output ($table -join "`n")
$readmePath = Join-Path $ProjectRoot 'README.md'
if ((Test-Path $readmePath) -and $proofExit -eq 0) {
    $readme = [IO.File]::ReadAllText($readmePath)
    $summary = ($content -split 'max steps used')[0].Trim()
    $replacement = "<!-- proof-summary:start -->`n" + ($table -join "`n") + "`n`n``````text`n$summary`n```````n<!-- proof-summary:end -->"
    $readme = [regex]::Replace($readme, '(?s)<!-- proof-summary:start -->.*?<!-- proof-summary:end -->', [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $replacement })
    [IO.File]::WriteAllText($readmePath, $readme)
}
exit $proofExit
