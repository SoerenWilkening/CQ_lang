# `review_a1_r1_probes` — Rule-13 round-1 probe corpus, Track A.1

ORACLE = `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass` (`main` 0c7380c).
SUBJECT = `/Users/sorenwilkening/Desktop/CQ_trackA/build/ir-pass` (`compare-select-parity`).
`./run.sh` prints every verdict table in `review_a1_r1.md` from both binaries; it writes only into
its own `mktemp -d` and rebuilds nothing. Recipes are the shipped ones (single TU: `clang -Iinclude
-include CQ.h -O1 -emit-llvm -S`; two TUs: the lib TU WITHOUT `-include CQ.h`, then `llvm-link`,
then ONE `cq-lowering`).

| probe | finding | ORACLE | SUBJECT |
|---|---|---|---|
| `k7_caller.c` + `lib3.c` | **F-A1-1 BLOCKER** — bd `9pum` unfixed, plain C | ACCEPT | **ACCEPT** (identical stream) |
| `k8_caller.c` + `lib3.c` | the same program WITHOUT the post-region `cq_theta(b,·)` | ACCEPT | DECLINE `predates a non-diagonal gate` |
| `k9_caller.c` + `lib3.c` | the DISCRIMINATOR — that line on ANOTHER register | ACCEPT | DECLINE, same string |
| `k6_caller.c` + `lib.c` | the SELECT spelling of `k7` — gate 2c is position-free, so no hole there | DECLINE | DECLINE |
| `o3_kick.ll` | hand-IR form: `control_phase_kickback_reject_cmp_round2_sibling_theta.ll` + one instruction | ACCEPT | **ACCEPT** |
| `b1.c`, `b2.c` | **F-A1-2** — the barrier reaches the RAIL ladder (accepts are correct) | DECLINE `measured before` | **ACCEPT** |
| `o7a_caller.c` + `lib2.c` | O-7's round-2 window on the barrier — CLOSED by the ungated rung (ii) | ACCEPT (miscompile) | DECLINE ✔ |
| `o7c.c` | guarded-only mint — accept control for the barrier | ACCEPT | ACCEPT |
| `c1.c` `c2.c` `c9.c` `c10.c` | **F-A1-3** — the cone over-declines valid circuits | ACCEPT | **DECLINE** |
| `c7.c` `c8.c` | the MIRROR of `c1`/`c2` — same physics, opposite verdict | ACCEPT | ACCEPT |
| `c3.c` `c4.c` | controls: a DIFFERENT register measured / measure-after | ACCEPT | ACCEPT |
| `sw1.ll` / `sw2.ll` | **F-A1-4** — `switch` vs `icmp`+`br` on a measured scrutinee | ACCEPT / ACCEPT | **ACCEPT** / DECLINE |
| `g2_caller.c` + `lib3.c`, `g3.c` | the backstop covering the 6.5 arm and the value arm (correct repairs) | ACCEPT | DECLINE ✔ |
| `sp1.c` `sp2.c` | O-5: `mintCondNetwork` is unreachable with a control read | DECLINE (specializer) | DECLINE (specializer) |
