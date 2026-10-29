# Local validation

Validated on 2026-10-29, Windows 11 Pro (10.0.26300).

| Environment | Command | Result |
|---|---|---|
| Windows PowerShell 5.1.26100.9711, fresh source copy with no Alire/build/proof artifacts | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1` | Exit 0 |
| PowerShell 7.6.5, project workspace | `./scripts/check.ps1` | Exit 0 |

Both runs built the CLI and test runner, passed the Ada and CLI integration tests, and proved all 107 library checks. No residual unproved checks, assumptions, justified checks or skipped analysis entries were present. Tool downloads were reused from Alire's machine-wide cache in the fresh-copy test.

The [proof report](PROOF_REPORT.md) and README retain the generated proof evidence. All twelve recorded source/project fingerprints were checked against the workspace. Raw validation and diagnostic logs are local artifacts and are excluded from version control. Reproduce the checks with `scripts/check.ps1`.

The CLI [demo transcript](DEMO.md) was captured from the actual executable. A tampered chain returned exit 1, and the same sampling seed reproduced the same five starts.
