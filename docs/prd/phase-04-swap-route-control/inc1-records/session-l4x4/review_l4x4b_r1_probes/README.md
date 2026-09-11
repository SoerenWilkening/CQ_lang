# Round-1 Rule-13 review probes — bd `l4x4` sub-increment l4x4.b

45 probes (42 single-TU + 3 two-TU). Written by the INDEPENDENT reviewer; none of
them touches `ir-pass/`, `include/`, `tests/` or `tools/`, and nothing here builds.

* `./run.sh [oracle|f2|subj]` — every `*.c` beside this file, lowered by one of the
  three read-only binaries (`oracle` = `main` 0c7380c, `f2` = the Track-C base
  578dbc4, `subj` = `l4x4b-bool-ry-arm`), printing `rc` + the diagnostic, or the
  emitted `cqrt_*` / `cq_template_*` stream.
* `./run_multi.sh` — the three TWO-TU round-2-taint-window probes in `multi/`,
  all three binaries (each is linked with the shipped 6.5 lib body
  `probes/impl/multi/w2_lib.c` via `llvm-link`).
* `sweep_f2_vs_subj.py` — every fixture in the subject's `ir-pass/test` through the
  F2 base and the subject, comparing exit code, diagnostic string and lowered
  stdout. Result: `files=1810 RCDIFF=15 DIAGDIFF=11 OUTDIFF=0`, and all 26 movers
  are files that do not exist at 578dbc4 — so over the **1782** `.ll` fixtures
  common to both trees it is **0 / 0 / 0**.

## Map

| prefix | what it attacks (brief item) |
|---|---|
| `r01`–`r05`, `s01`–`s02` | item 1 — the whole-DAG spine and the live control register `b` (dead / measured / chained / borrowed / borrow-is-the-terminal) |
| `n10`–`n12`, `g01`–`g04`, `y04` | item 2 — the negation's ORDER and its interactions (data use after, two regions, then-kickback, prep both seeds, θ=0, R6) |
| `x01`, `x02`, `x01c`, `n11` | item 2 — **finding F-1**: a non-finite / run-time angle under the negated arm, with the compare twin as the oracle |
| `h01`–`h03` | item 3 — H-1: the CONTROL-THETAS-FIRST ordering, a chained control, a control whose rotation lowering declines |
| `multi/w4`,`w5`,`w6` | item 8 — the round-2 taint window through the PREP, the NEGATED PREP and the NEGATED in-place arm |
| `f01`–`f03` | item 6 — F2 on the rail (the I-4 residual, the seed-is-`b` rival, a pinned `i32` seed) |
| `y01`,`y01c`,`y02`,`y03` | item 5 — R4's subject on a rail (the arm rotates an ANCESTOR of the condition's wire) and the derived-record guards |
| `u01`, `v01`, `r03` | shapes that decline for PRE-EXISTING reasons (multi-φ regions — bd `b6ap`; a merge-φ condition — bd `boi6`) |
| `wd_*` | width coverage i8/i16/i64/f32/f64/f80 from plain C |
| `i01`,`i01c`,`i02` | `cq_invert_begin/_end` (inert on both binaries — Phase 8, pre-existing) |
| `z01`,`z01c`,`z02` | Phase-6 specialization of a rail-region callee; a later region reading `b` |

See `../review_l4x4b_r1.md` for the verdict and the findings.
