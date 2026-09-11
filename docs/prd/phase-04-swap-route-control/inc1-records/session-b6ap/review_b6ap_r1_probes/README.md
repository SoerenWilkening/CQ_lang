# Probe family — Rule-13 review round 1, bd `test_C_libtooling-b6ap`

`./ab.sh <name>` runs `<name>.c` (or `<name>.s1.ll`) through BOTH binaries:
ORACLE `CQ_lang/build` (`main` 0c7380c) and SUBJECT `CQ_b6ap/build`
(`merge-phi-peel`), then links, runs, and reports STRICT stage 2b.
Full verdict table + analysis: `../review_b6ap_r1.md`.

## F-B6-1 — the CONFIRMED silent miscompile (the taint-growth guard hole)

| probe | consumer of the peeled mux | ORACLE | SUBJECT |
|---|---|---|---|
| `r20_clone_measured.c` | `cq_measure(helper(m))` | DECLINE `control flow` | **exit 0 — measures an UNRELATED rail** |
| `r23_clone_handpeel.s1.ll` | its HAND-PEELED twin | **exit 0, CORRECT** (26 lines, `cq_template_add_i32_hl`) | identical |
| `r07_escape_clone2.c` | `g_probe = helper(m)` | DECLINE | exit 0, prints `g=5` (helper of the handle tag) |
| `r08_handpeel_clone.s1.ll` | its twin | DECLINE `tainted value stored to memory` | same |
| `r04_escape_store.c` | `g_probe = m` | DECLINE | exit 0, prints the handle tag `4` |
| `r05_handpeel_store.s1.ll` | its twin | DECLINE `tainted value stored to memory` | same |
| `r11_escape_ptrstore.c` | `arr[1] = m` | DECLINE | exit 0, prints `4` |
| `r02_escape_sink.c` | `extern void cq_sink_probe(int)` | DECLINE | exit 0, `@cq_sink_probe(i32 %out)` |
| `r03_handpeel_escape.s1.ll` | its twin | DECLINE `unknown callee` | same |
| `r09_escape_ret64.c` / `r10_escape_printf.c` | `long long` ret / `printf` | DECLINE | DECLINE (loud — these two consumers are covered) |
| `r16_predmux_escape.c`, `r17_predmux_escape1.c` | the same escape where `-O1` itself builds the select | DECLINE both | DECLINE both — **so the hole is the peel's, not `-O1`'s** |

## F-B6-2 — guarded store + all-peelable merge

`g01_guarded_store_2phi.c` (ORACLE `guarded store with a merge value`; SUBJECT
exit 0 with the WHOLE 7.5 reversal missing) and its control `g02_guarded_ctrl.c`
(no merge φ ⇒ the full reversal runs on the ORACLE).

## Boundaries that HELD

`f01`..`f07` (fp/angle), `d01`/`d02` (the D1 one-φ vs two-φ unitary pair),
`s01` (stale record), `n01` (one rail, two SSA names), `u01`..`u06` + `x01`
(newly-tainted downstream consumers), `x02`/`x03` (poison / freeze incoming),
`m01_rz_eq_rz_unrolled.c` (the loop-twin-matrix cell, re-derived by hand),
`w03` (the classify-vs-emit taint window — not reached from `-O1`).
