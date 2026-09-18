# GATES — session 2026-09-21

Every row is hash-keyed to the binary it was measured on. Nothing copied forward.

```
PRE-LANDING  cq-opt 8280ea8d86bcaf4ed82cae92f65733fe8ae601086dfb721d58feeda55d8d9da2
             libCQPass.so 01fbe0c125ead5b40a77178e78278df8a43e1b0133f903c9f2d5bdd81a8d575f   (main 78b6bf64)
LANDED       cq-opt 3368af1262695d7e4c573d3958f0a9aa48e604bf5248e1b85a52362ac76f69dc
             libCQPass.so 48b8b4db61777082e98bf9f15da7d50ebe386a7d5342b1292c9f05b72260ffaf   (main 62b0b111)
```

⚠ **REPRODUCIBILITY, worth its own line.** The LANDED binary was built FIRST in a
throwaway worktree and then AGAIN in the primary tree after the merge, and the two
are **BIT-IDENTICAL**. Separately, the F-1/F-6 source edits are comment-only and the
binary is **bit-identical across them** — the cheapest possible proof that a
documentation fix is a documentation fix.

| gate | result | cited on |
|---|---|---|
| **BOUNDARY CONTROL, null** — the owner's `grover_oracle_uncompute.c` | **IDENTICAL on both**: 85 lowered lines, 50 trace lines, 2b `2 verified, 0 violation(s), 0 unproven`; lowered-IR and trace `diff` EMPTY | both |
| **BOUNDARY CONTROL, positive** — `tu9q_ht_rolled.c`, the branch's own customer | D → A, 67 lowered / 40 trace | both |
| the ten composed accepts | all **D → A**; exit 0, **stderr 0 bytes**, 2b STRICT `0 violation(s), 0 unproven`, link + run | LANDED |
| Rule-8 / multiplicity / dirty-free, ten accepts + four hand-unrolled twins | **clean** — but on `dephase.py`, **which was then found unsound** (see round 5 F-2) | LANDED |
| the same, re-run on round 5's edge-complete `entangle.py` | **26 composed traces, ONE finding**, and it is a loop-free program byte-identical on both binaries carrying the ruled `lyyf` warning. **No Rule-8 finding attributable to the composition** | both |
| the multiplicity trigger, NESTED shape (`m4`) | `cq_template_mul_i32_hl` **ONE mint** (trace line 3), **ONE `_unc`** (line 122), free (123), the interference `cqrt_ry_i32` (124) | LANDED |
| K-independence, `d3r` / `m4` / `o1` | **84 / 103 / 111** lowered lines at K = 3, 64 **and** 1000 | LANDED |
| rolled vs unrolled, 4 twin pairs | every delta is the `-O1` trip-1 const-fold class §4e ruling 2 blesses; **leak parity EXACT in 3 of 4**, the 4th diverging in the SAFE direction | LANDED |
| corpus A/B, all fixtures, exit + diagnostic + lowered-IR sha | **8 movers, 0 A→D**, 4 D→A, 1 D→D(string), 3 A→A(stream) over **2109** — exactly the branch's declared 8, on a base the branch never saw | 8280ea8d… vs 3368af12… |
| corpus A/B **null control** (MAIN vs MAIN, 120 fixtures) | **0 movers** — run BEFORE the real sweep | — |
| corpus A/B **positive control** (the branch's declared mover) | **1**, i.e. the harness can see a move it is known to have | — |
| `lit ir-pass/test` | **2112 discovered · 2111 passed · 1 XFAIL** | LANDED |
| full `ctest -j6`, gated worktree | **472/472 in 529.58 s** | 3368af12… |
| full `ctest -j6`, PRIMARY tree after the merge | **472/472 in 505.80 s** | 3368af12… (bit-identical) |
| bd `6n1s` merge-order gate | `git merge-base --is-ancestor 22a0ab11 main` → **true**, so the backstop is carried by construction; `i1_g8_carried` **declines on BOTH**. ⚠ Remains a REBASE hazard, never a merge one | both |
| the replacement L1 pin | fires **character-for-character on BOTH binaries** | both |
| the F-1 fixture pair | decline fires on LANDED; ⚠ **PRE-LANDING ACCEPTS it** at exit 0 with the rail live across the trailing `cqrt_ry` under the ruled `lyyf` warning — on this shape the landing is strictly **STRICTER** | both |
| every new golden's non-vacuity | the PRE-LANDING compiler **DECLINES all six** | 8280ea8d… |
| `add_test` hygiene after registration | **0 duplicate names**, sweep-last anchor preserved, 466 → **472** | — |

## Rule-13 round (independent agent, wrote neither increment)

| round | subject | verdict | P1 | records |
|---|---|---|---|---|
| 5 | bd `4jok` — the COMPOSED accept surface | `CLEAR-WITH-ITEMS` | **0** | `round5/` (35 probes, 2 harnesses, 396 lines) |

**Findings: 1 × P2, 6 × P3.** F-1 (P2) and F-6 corrected at the source in the
landing commit; F-4 and F-5 discharged by the fixtures; F-7 filed as bd `a945`;
F-2 closed by superseding the instrument; F-3 positive.

⚠ **THE ROUND RAN NO SUITE AND NO LIT, BY INSTRUCTION**, so it could not perturb
the binaries it measured — and so **no `FileCheck` line was executed in it**. It
also states two limits itself: it had only two binaries, so it **cannot certify
anything "composition-only"** (that attribution remains round 3's, on round 3's
base); and it found the probe-design trap (bd `46oo`) in its own first break probe
as well as in round 3's.

## Counts at close (re-measured, not quoted)

| quantity | value | was (2026-09-20) |
|---|---|---|
| ctest entries | **472** | 466 |
| `^e2e-` | **462** | 456 |
| `^e2e-slice-` | **404** | 398 |
| `twin-identical` | **44** | 44 (unchanged) |
| `ls ir-pass/test/*.ll` | **2112** | 2109 |
| `ls tests/e2e/*.expected.log` | **406** | 400 |
| twin matrix | **312** + **70** = 382 | unchanged |

⚠ **THE FIXTURE DELTA UNDERSTATES THE CHANGE BY A FACTOR OF THREE.** +3 files, but
**EIGHT existing fixtures were RE-DERIVED**, four of them changing verdict. A
count of files is not a count of work, and on this landing it is not even a count
of what a reviewer has to re-read.
