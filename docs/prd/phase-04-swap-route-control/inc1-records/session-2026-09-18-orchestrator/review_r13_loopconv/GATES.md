# GATES — Rule-13 review of the loop-group conversions (session 2026-09-18)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <time>`

**ORACLE verified on disk before any measurement below**, per PROTOCOL:

```
$ shasum -a 256 build/ir-pass/cq-opt
9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3  build/ir-pass/cq-opt
```
matches `$SES/PROTOCOL.md`'s frozen block character-for-character. `git log --oneline -1` =
`cff8f7ac` (pass source unchanged since `95949550`).

**This role runs NO build and NO suite.** Every line below is ONE per-probe pipeline run
(`clang -O1 -g` → `cq-opt` → `free_pairing_check.py` → link → run), i.e. **no gate longer than a
single fixture**, so nothing was announced in `$SES/GATES_INFLIGHT.md` and nothing needed to be.
**No `ir-pass-lit`, no `ctest`, no corpus sweep, no matrix, no equivalence sweep was run by me.**

Redundancy check (PROTOCOL §6.1): I cited nothing and ran nothing another agent owns. I read
`$THIS/GATES.md` before starting; none of its recorded lines covers any probe below (they are the
socratic session's own s1/s2/s3/w2k/n1–n3/b7*/b10/b11/w2h*/s4 programs and the owner's file — a
disjoint probe set), so there was no line to cite.

| gate | hash16 | result verbatim | who | when |
|---|---|---|---|---|
| harness self-attack: 0-byte `.c` | 9bd01598d574b344 | `selfattack_empty \| VACUOUS-EMPTY-SOURCE` | reviewer | 2026-09-17 |
| harness self-attack: quantum-free `.c` | 9bd01598d574b344 | `selfattack_noquantum \| VACUOUS-NO-QUANTUM` | reviewer | 2026-09-17 |
| harness self-attack: broken 2b path | 9bd01598d574b344 | first spelling printed `2b: … cannot read ./work/*.s2.ll` **while still scoring ACCEPT**; guard added, now `INSTRUMENT-BROKEN-2B` + exit 2 | reviewer | 2026-09-17 |
| probe `c1_cmp_rail_data` | 9bd01598d574b344 | `ACCEPT \| trace=14 \| 2b: 1 rail mint(s) of which 1 left allocated, 2 template rail mint(s) of which 0 left dirty, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven` | reviewer | 2026-09-17 |
| probe `c1_cmp_rail_data_un` | 9bd01598d574b344 | `ACCEPT \| trace=14`; `diff` vs rolled **EMPTY** | reviewer | 2026-09-17 |
| probe `c2_inloop_rotation` | 9bd01598d574b344 | `ACCEPT \| trace=24 \| 2b: … 3 template rail mint(s) of which 0 left dirty, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven` | reviewer | 2026-09-17 |
| probe `c2_inloop_rotation_un` | 9bd01598d574b344 | `ACCEPT \| trace=24`; symbol multiset delta EMPTY **and** argument-level multiset delta EMPTY | reviewer | 2026-09-17 |
| probes `a1`–`a5` (c1 attacks, 10 modules) | 9bd01598d574b344 | a1 A:15==15 BYTE-IDENTICAL · a2 A:18==18 BYTE-IDENTICAL · a3 A:24==24 BYTE-IDENTICAL · a4 DECLINE `taint escape: tainted value muxed by a classical-condition phi` · a5 DECLINE `cq loop lowering: rolled body leaks a rail entangled with a rotated register` (twin A:15) | reviewer | 2026-09-17 |
| probes `b1`–`b6` (c2 attacks, 12 modules) | 9bd01598d574b344 | b1 A:25 vs 25 arg-multiset EMPTY · b2 DECLINE `loop-carried tainted value crosses iterations` · b3 A:44 vs 45 (one extra measure-owned copy in the TWIN) · b4 DECLINE taint escape · b5 DECLINE `rolled body leaks …` · b6 A:45 vs 46, discharges 4/4/4 both | reviewer | 2026-09-17 |
| probes `r3`, `r1_triple_nest_mid_rail`, `r1_triple_deeper`, `r3_outer_rail_inner_marked_nodeeper` | 9bd01598d574b344 | r3 DECLINE `rolled body leaks a rail entangled with a rotated register` (twin A:42) · r1 DECLINE (twin A:72) · r1_triple_deeper (DEPTH 4) DECLINE · r3_outer_rail_interior DECLINE `loop-carried tainted value crosses iterations` | reviewer | 2026-09-17 |
| probes `t5c`–`t5k` (break path, 15 modules) | 9bd01598d574b344 | t5c A:14 **BYTE-IDENTICAL** to `t5c_ref_two_trips` A:14 · argc sweep lim=2/3/4/5/6 → 2/3/4/4/4 trips, mints==uncs==frees at every break point · t5d/t5e DECLINE bd `3d8q` · t5f A:23 BYTE-IDENTICAL to `t5f_ref_lim2` A:23 · t5g A:8 · **t5h A:11 vs flat 15, 2b `1 left dirty, 0 cqrt_free site(s)`** · **t5h_rot A:12 + warning `non-diagonal gate over a live derived record`, `1 left dirty`** · t5i A:31==31 `0 left dirty, 2 verified` · t5i_rot A:32 `0 left dirty` no warning · **t5j A:18, `1 left dirty, 0 cqrt_free site(s)`, warning** · t5k DECLINE `rolled body leaks a rail entangled with a rotated register` | reviewer | 2026-09-17 |
| `free_pairing_check.py` exit code on the F-1 witness | 9bd01598d574b344 | `… 3 template rail mint(s) of which 1 left dirty, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven` → `EXIT=0` | reviewer | 2026-09-17 |

⚠ **ONE INSTRUMENT OF MINE LIED AND IS RECORDED RATHER THAN HIDDEN** (`CLAUDE.md` L10). An argc
sweep written in **zsh** used an unquoted `$args`; **zsh does not word-split an unquoted parameter**,
so every row passed ONE argument and the table read `lim=4 → 3 trips` — which is exactly what a
DROPPED LOOP TRIP looks like. It was caught only because the same binary, run by hand with literal
arguments, gave 4 trips. The replacement is `probes/argsweep.sh`, which is `#!/bin/bash` and builds
the argument list with `set --`. **Nothing in this review is reported from the zsh spelling.**
