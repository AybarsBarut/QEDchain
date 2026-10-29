# ChainGuard proof report

Generated (UTC): 2026-10-29 08:52:51Z

Command: `alr -n exec -- gnatprove -P chainguard.gpr -u chainguard-chain.adb chainguard-chain.ads chainguard-sampling.adb chainguard-sampling.ads chainguard-sha256.adb chainguard-sha256.ads chainguard-types.ads chainguard-verify.adb chainguard-verify.ads chainguard.ads --level=2 --mode=all --report=all --checks-as-errors=on`

Process/gate exit code: 0

## Package checks

| Package | Total checks | Proved | Unproved |
|---|---:|---:|---:|
| chainguard-chain | 33 | 33 | 0 |
| chainguard-sampling | 9 | 9 | 0 |
| chainguard-sha256 | 35 | 35 | 0 |
| chainguard-types | 0 | 0 | 0 |
| chainguard-verify | 30 | 30 | 0 |
| chainguard | 0 | 0 | 0 |
| **Total** | **107** | **107** | **0** |

Counts include flow checks and prover checks. Zero-check specification units are still analyzed.

Assumptions or skipped-analysis entries: 0

## Residual unproved checks

None.

## Proof scope

Silver: all library packages. Gold: block/link/genesis definitions, index induction, Append preservation, verification equivalence and sampling bounds/state transition. Payload_Tamper_Lemma proves only a conditional statement whose explicit premise is that the two computed hashes differ. SHA-256 functional correctness and collision resistance are not proved. CLI file I/O and the test harness are outside SPARK analysis.

## Toolchain

```text
alr 2.1.1
FSF 16.1.0
Why3 for gnatprove version 1.8.2+git
C:\Users\4rchura\AppData\Local\alire\cache\releases\gnatprove_16.1.0_f3c62ad9\libexec\spark\bin\alt-ergo.exe: Alt-Ergo version 2.6.1
C:\Users\4rchura\AppData\Local\alire\cache\releases\gnatprove_16.1.0_f3c62ad9\libexec\spark\bin\cvc5.exe: This is cvc5 version 1.3.2 [git 86cecd8 on branch HEAD]
C:\Users\4rchura\AppData\Local\alire\cache\releases\gnatprove_16.1.0_f3c62ad9\libexec\spark\bin\z3.exe: Z3 version 4.15.4 - 64 bit
```

## Raw GNATprove summary

```text
=========================
Summary of SPARK analysis
=========================

------------------------------------------------------------------------------------------------------------
SPARK Analysis results        Total        Flow                               Provers   Justified   Unproved
------------------------------------------------------------------------------------------------------------
Data Dependencies                 1           1                                     .           .          .
Flow Dependencies                 .           .                                     .           .          .
Initialization                   12          12                                     .           .          .
Non-Aliasing                      1           1                                     .           .          .
Run-time Checks                  51           .      51 (CVC5 99%, Z3 1%, altergo 1%)           .          .
Assertions                       12           .    12 (CVC5 76%, Z3 14%, altergo 10%)           .          .
Functional Contracts             14           .      14 (CVC5 84%, Z3 9%, altergo 6%)           .          .
LSP Verification                  .           .                                     .           .          .
Termination                      16          14                              2 (CVC5)           .          .
Concurrency                       .           .                                     .           .          .
------------------------------------------------------------------------------------------------------------
Total                           107    28 (26%)                              79 (74%)           .          .


max steps used for successful proof: 7014

============================
Most difficult proved checks
============================

chainguard-sampling.adb:19:44: divide by zero proved in max 1 seconds

========================
Detailed analysis report
========================

Analyzed 6 units
in unit chainguard, 1 subprograms and packages out of 1 analyzed
  ChainGuard at chainguard.ads:1 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
in unit chainguard-chain, 9 subprograms and packages out of 9 analyzed
  ChainGuard.Chain at chainguard-chain.ads:2 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (1 checks)
  ChainGuard.Chain.Append at chainguard-chain.ads:33 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (7 checks)
  ChainGuard.Chain.Block_Valid at chainguard-chain.ads:20 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
  ChainGuard.Chain.Chain_Valid at chainguard-chain.ads:27 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (3 checks)
  ChainGuard.Chain.Compute_Block_Hash at chainguard-chain.ads:17 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (1 checks)
  ChainGuard.Chain.Genesis_Valid at chainguard-chain.ads:25 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
  ChainGuard.Chain.Index_Lemma at chainguard-chain.adb:17 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (13 checks)
  ChainGuard.Chain.Link_Valid at chainguard-chain.ads:22 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
  ChainGuard.Chain.Payload_Tamper_Lemma at chainguard-chain.ads:40 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (1 checks)
in unit chainguard-sampling, 4 subprograms and packages out of 4 analyzed
  ChainGuard.Sampling at chainguard-sampling.ads:2 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
  ChainGuard.Sampling.Next_State at chainguard-sampling.ads:6 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
  ChainGuard.Sampling.Output at chainguard-sampling.ads:7 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
  ChainGuard.Sampling.Pick_Segment at chainguard-sampling.ads:8 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (6 checks)
in unit chainguard-sha256, 9 subprograms and packages out of 9 analyzed
  ChainGuard.SHA256 at chainguard-sha256.ads:2 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
  ChainGuard.SHA256.Bytes_Processed at chainguard-sha256.ads:6 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
  ChainGuard.SHA256.Compress at chainguard-sha256.adb:23 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
  ChainGuard.SHA256.Context at chainguard-sha256.ads:20 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
  ChainGuard.SHA256.Digest at chainguard-sha256.ads:13 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (1 checks)
  ChainGuard.SHA256.Feed at chainguard-sha256.adb:56 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (3 checks)
  ChainGuard.SHA256.Finish at chainguard-sha256.ads:12 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (9 checks)
  ChainGuard.SHA256.Initialize at chainguard-sha256.ads:7 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (1 checks)
  ChainGuard.SHA256.Update at chainguard-sha256.ads:9 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (7 checks)
in unit chainguard-types, 1 subprograms and packages out of 1 analyzed
  ChainGuard.Types at chainguard-types.ads:2 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
in unit chainguard-verify, 5 subprograms and packages out of 5 analyzed
  ChainGuard.Verify at chainguard-verify.ads:3 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (0 checks)
  ChainGuard.Verify.Segment_Valid at chainguard-verify.ads:8 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (7 checks)
  ChainGuard.Verify.Verify_Chain at chainguard-verify.ads:23 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (2 checks)
  ChainGuard.Verify.Verify_Link at chainguard-verify.ads:4 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (1 checks)
  ChainGuard.Verify.Verify_Segment at chainguard-verify.ads:18 flow analyzed (0 errors, 0 checks, 0 warnings and 0 pragma Assume statements) and proved (16 checks)

```

## Source fingerprints

| Source | SHA-256 |
|---|---|
| alire.toml | 8fe74d8da0ab5dc1bb62e3116bed4186170e01f5045ec1ac865aced700368d37 |
| chainguard-chain.adb | e732d95d836efb06bad69356c7258362a6e1ce55664b491528b9c359ea91b8ed |
| chainguard-chain.ads | e2bd8c38787f07890584b3f6f460b8c2cde0790b75ad690dba2bf422187c7fbd |
| chainguard-sampling.adb | 6eea04272de2627dabaa4de148134e26d698afef5712c57ba5a1283987c2af54 |
| chainguard-sampling.ads | 5fbae0c5870ac976e70a12411bb00d3ab49e19030ec5e023d90b169d53d07e67 |
| chainguard-sha256.adb | cff0e006829b47c8d66eda318ff58b23a5db9c0db61efc3e2a0164ba03a46e4c |
| chainguard-sha256.ads | 6cab4d91d1cd5e8c13a237687789910eead007377e9a15026a8d5875f9feb9e4 |
| chainguard-types.ads | 0d3921b56e7a61b7a206c821226230484e178ad46848139c36f6344e602aee6d |
| chainguard-verify.adb | 722852ca238cf055e68040186a29107e57866d4d9c334abd5cf4b1850b48d94f |
| chainguard-verify.ads | 8a123b8aa0d6cdb48514cfa57f7ae2a2cfe77c03ae8042946374ada2062e593f |
| chainguard.ads | e0ef6ccef2d1d2ac3a7b64a1485c85b5fbd1505ec49335123df14f9f856f1d7a |
| chainguard.gpr | c698a5b547d1a7e2d957aaa6aab57c014b0bd02d68b458ea0a04d8310507fb5b |
