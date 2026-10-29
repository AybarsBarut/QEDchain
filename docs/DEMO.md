# CLI demo

Captured from the local Windows CLI using the 12-part manifest in the README.

```text
PS> .\bin\chainguard.exe build demo\manifest.txt -o demo\chain.bin
built 12 blocks
exit 0

PS> .\bin\chainguard.exe verify demo\chain.bin
valid
exit 0

PS> .\bin\chainguard.exe tamper demo\chain.bin --block 7 -o demo\bad.bin
tampered
exit 0

PS> .\bin\chainguard.exe verify demo\bad.bin
invalid
exit 1

PS> .\bin\chainguard.exe sample demo\chain.bin --count 5 --seed 42
sample start=0 count=8 valid
sample start=3 count=8 valid
sample start=1 count=8 valid
sample start=0 count=8 valid
sample start=3 count=8 valid
exit 0

PS> .\bin\chainguard.exe sample demo\bad.bin --count 5 --seed 42
sample start=0 count=8 invalid
sample start=3 count=8 invalid
sample start=1 count=8 invalid
sample start=0 count=8 invalid
sample start=3 count=8 invalid
exit 1

```
