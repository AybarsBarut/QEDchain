$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
$fixtures = Join-Path $root 'bin\cli fixtures'
New-Item -ItemType Directory -Force $fixtures | Out-Null
$exe = Join-Path $root 'bin\chainguard.exe'
$stdout = Join-Path $fixtures 'stdout.txt'
$stderr = Join-Path $fixtures 'stderr.txt'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Check([bool]$Condition, [string]$Label) {
    if (-not $Condition) { throw "FAIL: $Label" }
}
function Invoke-CLI([string[]]$CliArgs, [int]$Expected) {
    $quoted = @($CliArgs | ForEach-Object { '"' + $_ + '"' })
    $p = Start-Process -FilePath $exe -ArgumentList $quoted -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $out = [IO.File]::ReadAllText($stdout)
    $err = [IO.File]::ReadAllText($stderr)
    Check ($p.ExitCode -eq $Expected) "CLI [$CliArgs] exit $($p.ExitCode), expected $Expected; $out $err"
    return $out.Trim()
}
function Hex([byte[]]$Bytes) { return [BitConverter]::ToString($Bytes) }

$sizes = @(0, 1, 55, 56, 57, 63, 64, 65, 8191, 8192, 8193, 9000)
$paths = @()
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $name = "part $i.bin"
    $paths += $name
    $data = New-Object byte[] $sizes[$i]
    for ($j = 0; $j -lt $data.Length; $j++) { $data[$j] = ($j * 17 + $i) % 256 }
    [IO.File]::WriteAllBytes((Join-Path $fixtures $name), $data)
}
$manifest = Join-Path $fixtures 'manifest.txt'
[IO.File]::WriteAllLines($manifest, [string[]]$paths, $utf8)
$chain = Join-Path $fixtures 'chain.bin'
$bad = Join-Path $fixtures 'bad.bin'
$null = Invoke-CLI @('build', $manifest, '-o', $chain) 0
$null = Invoke-CLI @('verify', $chain) 0
$bytes = [IO.File]::ReadAllBytes($chain)
Check ($bytes.Length -eq 12 + 104 * $sizes.Count) 'binary size'
Check ([Text.Encoding]::ASCII.GetString($bytes, 0, 8) -eq 'CGUARD01') 'magic'
Check ((Hex $bytes[8..11]) -eq '00-00-00-0C') 'big endian length'

# Independent .NET SHA-256 oracle validates file hashing, record layout and links.
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $previous = New-Object byte[] 32
    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $offset = 12 + 104 * $i
        $index = New-Object byte[] 8
        $index[7] = $i
        $payload = $sha.ComputeHash([IO.File]::ReadAllBytes((Join-Path $fixtures $paths[$i])))
        $input = [byte[]]($index + $previous + $payload)
        $blockHash = $sha.ComputeHash($input)
        $expected = [byte[]]($input + $blockHash)
        Check ((Hex $bytes[$offset..($offset + 103)]) -eq (Hex $expected)) "independent record $i"
        $previous = $blockHash
    }
} finally { $sha.Dispose() }

$null = Invoke-CLI @('tamper', $chain, '--block', '7', '-o', $bad) 0
Check ((Invoke-CLI @('verify', $bad) 1) -eq 'invalid') 'tamper result'
$sample1 = Invoke-CLI @('sample', $chain, '--count', '5', '--seed', '42') 0
$sample2 = Invoke-CLI @('sample', $chain, '--count', '5', '--seed', '42') 0
Check ($sample1 -eq $sample2) 'CLI deterministic samples'
$null = Invoke-CLI @('sample', $bad, '--count', '5', '--seed', '42', '--length', '12') 1
$null = Invoke-CLI @('sample', $chain, '--count', '0', '--seed', '42') 2
$null = Invoke-CLI @('sample', $chain, '--count', '1', '--seed', '18446744073709551616') 2
$null = Invoke-CLI @('sample', $chain, '--count', '1', '--seed', '42', '--length', '13') 2
$null = Invoke-CLI @('tamper', $chain, '--block', '12', '-o', $bad) 2
$null = Invoke-CLI @('tamper', $chain, '--block', '-1', '-o', $bad) 2
$null = Invoke-CLI @('unknown') 2
$null = Invoke-CLI @('verify', (Join-Path $fixtures 'missing.bin')) 2

$malformed = Join-Path $fixtures 'malformed.bin'
[IO.File]::WriteAllBytes($malformed, [byte[]]@())
$null = Invoke-CLI @('verify', $malformed) 2
[IO.File]::WriteAllBytes($malformed, [byte[]]$bytes[0..10])
$null = Invoke-CLI @('verify', $malformed) 2
[IO.File]::WriteAllBytes($malformed, [byte[]]$bytes[0..($bytes.Length - 2)])
$null = Invoke-CLI @('verify', $malformed) 2
[IO.File]::WriteAllBytes($malformed, [byte[]]($bytes + [byte]0))
$null = Invoke-CLI @('verify', $malformed) 2
$changed = $bytes.Clone()
$changed[0] = 0
[IO.File]::WriteAllBytes($malformed, $changed)
$null = Invoke-CLI @('verify', $malformed) 2
$changed = $bytes.Clone()
$changed[8] = 255
[IO.File]::WriteAllBytes($malformed, $changed)
$null = Invoke-CLI @('verify', $malformed) 2

# An empty manifest is a valid empty chain, but has no nonempty sample window.
$emptyManifest = Join-Path $fixtures 'empty.txt'
$emptyChain = Join-Path $fixtures 'empty.bin'
[IO.File]::WriteAllText($emptyManifest, '', $utf8)
$null = Invoke-CLI @('build', $emptyManifest, '-o', $emptyChain) 0
$null = Invoke-CLI @('verify', $emptyChain) 0
$null = Invoke-CLI @('sample', $emptyChain, '--count', '1', '--seed', '0') 2
$invalidManifest = Join-Path $fixtures 'invalid.txt'
[IO.File]::WriteAllText($invalidManifest, "`n", $utf8)
$null = Invoke-CLI @('build', $invalidManifest, '-o', $emptyChain) 2
[IO.File]::WriteAllText($invalidManifest, 'nonexistent-file.bin', $utf8)
$null = Invoke-CLI @('build', $invalidManifest, '-o', $emptyChain) 2
Write-Output 'PASS: CLI integration, independent SHA-256 oracle, malformed input and exit codes'
