# Round-3 probe corpus — bd `test_C_libtooling-r9e5` 1b-B.1

Written by the ROUND-3 independent Rule-13 reviewer. Nothing here is a test
fixture; it is the measurement record behind `review_b1_r3.md`.

* `run.sh [PRE|PREB1|POST] [glob]` — the 40 hand-IR (`ll/`) + 4 plain-C (`c/`)
  single-TU probes. `POST` = the tree under review (`build/ir-pass`, a1e6d62 +
  the F-B1R2-1 fix), `PRE` = checkpoint **f8d29e8** (`scratchpad/fix_r2/pre`),
  `PREB1` = the pre-B.1 pair (`scratchpad/impl_b1/pre`).
* `run_multi.sh [PRE|PREB1|POST] [glob]` — the 10 TWO-TU probes (`multi/`),
  through the shipped 6.5 recipe: per-TU `clang -O1` IR, `llvm-link`, ONE
  `cq-lowering`.
* `corpusdiff.sh [PRE|PREB1]` — every `ir-pass/test/*.ll` on both binaries,
  classified RCDIFF / DIAGDIFF / OUTDIFF.
* `VERDICTS_*.txt` — the saved verdict tables; `out/` the traces and stderr. The
  intermediate `.ll` and the linked binaries are pruned; re-run a runner to
  regenerate them.

Naming: `r*` = the round-2 taint window through a consumer or recording site the
fix report had no program for; `x*` = the QROM taint-growth vector; `p*` =
plain-C consumer probes (guarded store, clone, spine); `m*` = the two-TU
plain-C windows. Every `r`/`m` decline probe is paired with a CONTROL that
differs only by the deleted sibling and must accept byte-identically.
