# `fix_r2_probes/` — Track W, FIX round 2 (bd `wx8g`, 2026-09-14)

Artefacts for `FIX_W_R2.md`. Every `.ll` the harnesses produce is `-s`-checked before use, and every
harness writes ONLY inside this worktree.

| file | what |
|---|---|
| `fx.sh` | the two-TU `llvm-link` **6.5 recipe with `-g`**, mirroring `tests/e2e/run_slice_multi.sh`. `fx.sh <sub\|ora> <cqTU> [libTU]`. Prints the decline message AND the source anchor — this is the only recipe that can see the F-W2-5 class, because **no hand-written `.ll` in this tree carries a source location at a decline site.** |
| `w2i2_h1_round2.c` · `w2i2_lib.c` · `w2i3_h1_cmpcond.c` | the two H-1 modules, verbatim copies of the round-2 review's. `.fxsub.*` / `.fxora.*` are the post-fix captures. |
| `anchor_sweep.sh` · `anchor_sweep.txt` · `corpus/` | 85 `.c` compiled `-O1 -g` single-TU and run through BOTH binaries; the `.txt` records verdict + message + ANCHOR per (probe, binary). |
| `twins.sh` | the 8 twin pairs (+ `w_l`), rolled vs hand-unrolled, byte-compared. |
| `disclose.sh` | the D-1 / D-2 re-measurement on both binaries, with the twin diff. |

⚠ **`corpus/` IS A VERBATIM COPY, NOT A SECOND PROBE SET.** Its 85 `.c` are the round-2 review's
`trackW/review_r2_probes/*.c` plus this track's own `trackW/probes/*.c`, copied so this record is
self-contained (the review dir is untracked in the main checkout at the time of writing). Do not read a
corpus file as independent evidence of anything its source dir already says, and if the two ever
disagree the SOURCE dir wins.
