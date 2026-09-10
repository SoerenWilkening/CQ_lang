# review_b1_r2_probes — the ROUND-2 Rule-13 probe corpus for bd `r9e5` 1b-B.1

76 programs: `c/` 26 plain C at `clang -O1`, `ll/` 47 hand IR, `multi/` 3 two-TU programs
(the shipped 6.5 recipe: per-TU `-O1` IR -> `llvm-link` -> ONE `cq-lowering`).

* `run.sh [PRE|POST] [glob]` — the 73 single-TU probes: clang -> cq-opt -> stage 2b -> link -> run.
  One line per probe; artefacts land in `out/<PRE|POST>/`.
* `run_multi.sh [PRE|POST]` — the two two-TU probes (`e12` rail-but-sunk, `e13` compare).
  `multi/e16_*.c` is the plain-C RAIL reproducer of F-B1R2-1; run it the same way.
* `corpusdiff.sh` — every `ir-pass/test/*.ll` on both binaries, RCDIFF/DIAGDIFF/OUTDIFF.
  Result at review time: `SCANNED=1765 MOVERS=23`, all 23 in the new B.1 family
  (`CORPUS_MOVERS.txt`).
* `VERDICTS_PRE.txt` / `VERDICTS_POST.txt` — the committed verdict tables (35 movers, all
  DECLINE -> ACCEPT; 6 accept on both, byte-identical; 0 accept -> decline).

`PRE` is the saved pre-B.1 pair under the session scratch dir (`CQ_PRE=` to override);
`POST` is `build/ir-pass/{cq-opt,libCQPass.so}`.

THE FINDING: `ll/e04` + `ll/e05` (the discriminating pair), `ll/e06`, `ll/e07`, `ll/e11`
(the accept that must survive any fix), `ll/e08` / `multi/e13` (the PRE-EXISTING compare
twin, accepts byte-identically on both binaries), `multi/e16_*.c` (plain C, rail spelling,
DECLINE on PRE and a wrong unitary on POST). See `../review_b1_r2.md` §2.
