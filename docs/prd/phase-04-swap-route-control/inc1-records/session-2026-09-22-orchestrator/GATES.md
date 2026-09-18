# GATES — session 2026-09-22 (bd `test_C_libtooling-fn1q` increment 1)

Every row is hash-keyed to the binary it was measured on. Nothing copied forward.

```
ORACLE       cq-opt 3368af1262695d7e4c573d3958f0a9aa48e604bf5248e1b85a52362ac76f69dc
             libCQPass.so 48b8b4db61777082e98bf9f15da7d50ebe386a7d5342b1292c9f05b72260ffaf   (main e107a177)
SUBJECT-A    cq-opt 3497126f3528e8ea4727c39be5e4d7cec610afc3c0853c43e101b17ed496513f   (the four-conjunct cone)
SUBJECT-B    cq-opt e4f842bb7fb132cb8bdae7af82c53b22c1d9ea681dd241359171acbee7fb89b4   (+ the Reject() hygiene edit)
SUBJECT      cq-opt 1b396ed08b01b8ecac7b268ba1d11ec3a90200e945ed091a43bf34ff23ad1c9e   (+ (K5), F-2/F-3 comment work)
             libCQPass.so f3a372fc275bcf15f2b3632b1fe3b586da086d6cc2040f0147675abe6cdcbe75
```

⚠ **REPRODUCIBILITY.** The ORACLE was rebuilt from scratch in a clean worktree at
`e107a177` and came out **BIT-IDENTICAL** to the hashes recorded at the 2026-09-21
close. The build is reproducible; a hash mismatch is a real difference.

⚠ **SUBJECT-A → SUBJECT-B WAS PROVED EQUIVALENT, NOT ASSUMED.** The hygiene edit
(`Reject()` clearing the cone on the false path; a reference instead of a nullable
pointer) is behaviour-neutral by argument, and the argument was checked: a full
2117-fixture A/B between the two binaries reports **0 movers**. That is what lets
SUBJECT-A's full `ctest` result be cited for SUBJECT-B.

| gate | result | cited on |
|---|---|---|
| full `ctest -j6`, FINAL binary | **473/473 in 529.47 s**, load 2.9 → 72 (it rose under other agents mid-run) — comparable with the 2026-09-21 quiet-box 505.80 s | **SUBJECT** |
| full `ctest -j6`, before (K5) | **473/473 in 922.16 s** ⚠ at load **112–140** — heavy concurrent agent load, NOT comparable, and quoted with its load per Rule 19 | SUBJECT-A |
| `lit ir-pass/test`, standalone | **2121 discovered · 2120 passed · 1 XFAIL**, 49.91 s | SUBJECT |
| corpus A/B **null control** (ORACLE vs ORACLE), run BEFORE the real sweep | **0 movers of 2117** | — |
| corpus A/B **positive control** (the increment's own new accept fixture) | **1** — the harness can see a move it is known to have | — |
| corpus A/B, all fixtures, exit + diagnostic + lowered-IR sha | **1 D→A, 0 A→D, 0 string moves, 0 stream moves** of 2117 | ORACLE vs SUBJECT-A |
| corpus A/B, SUBJECT-A vs SUBJECT-B | **0 movers of 2117** (the hygiene equivalence above) | — |
| corpus A/B, final, all **2121** fixtures | **0 A→D · 1 D→A · 1 decline-string move · 0 stream moves** — ⚠ **both movers are the increment's own new fixtures**, and the string mover DECLINES on both binaries (ORACLE at the stray rule, SUBJECT at the round-2 fence). Null control re-run FIRST on the fixed harness: **0 of 2121** | ORACLE vs SUBJECT |
| twin identity, mechanical | `control_swap_value_accept_arm_cone{,_prehoisted_twin}.ll` lowered FUNCTION BODIES `diff`-identical, asserted by a RUN line, and **mutation-validated** (perturb one constant in the subject → the twin goes RED, restore → green) | SUBJECT-A |
| new fixtures' non-vacuity | the accept fixture **DECLINES on the ORACLE** (`impure value arm`); the e2e slice's source likewise | ORACLE |
| decline fixtures | all decline on **BOTH** binaries — they pin a decline that must SURVIVE | both |
| stage 2b on the new slice | STRICT, `1 verified, 0 violation(s), 0 unproven` | SUBJECT |
| **protocol item 5** — rolled vs unrolled vs flat, TRAILING non-diagonal gate on the condition's register | **all three DECLINE, identically on both binaries**, at the 2c condition-wire fence (`condition predates a non-diagonal gate`). The increment adds no accept in that presence | both |
| the same, trailing gate on the MERGED register | `trail_arm` declines identically on both (stale-reader fence); `trail_arm_pre` accepts identically on both, byte-identical, with the ruled `lyyf` warning | both |
| Rule-8 / dirty-free / multiplicity on the new slice's trace, via the **round-5 `entangle.py`** (edge-complete, 18 boundary controls — ⚠ NOT `dephase.py`, which ships marked SUPERSEDED with its two misses) | **18/18 controls as pinned**; the slice reports `OK: no dirty free, no UAF, no multiplicity, no entangled rail live across any uncontrolled Ry` | SUBJECT |
| `show_pipeline.sh` banner | verified in BOTH directions: a declining program prints `STAGE 2 · DECLINED` and exits with the compiler's status; an accepting program still runs to the trace and exits 0 | SUBJECT |

## Rule-13 round (independent agent, wrote none of this code)

| round | subject | verdict | P1 | records |
|---|---|---|---|---|
| 1 | the cone increment | **`CLEAR-WITH-ITEMS`** | **0** | `REVIEW_R13.md`, probes in `probes/` |

**Findings: 2 × P2, 6 × P3.** Both P2s and four P3s are addressed in this session:

* **F-1 (P2) — FIXED, and it is the finding worth reading.** A `cq_phi` /
  `cq_measure` / `__cq_invert_begin` declaration carrying `speculatable
  memory(none) nounwind willreturn` passed all four conjuncts and was HOISTED into
  the pred, where the branch phase is uncontrolled and `deleteGlobalPhases` DELETES
  it — `opt` exit 0 with no `cqrt_rz_i1` in the stream. **Before the increment the
  containment was STRUCTURAL** (any non-chain arm op declined), and the four
  conjuncts replaced that structure without naming CQ's own calls. Closed by a
  fifth conjunct **(K5)**, asked as the question it means — "does a CQ stage OWN
  this call?", answered by *declared external vs `@llvm.*` intrinsic* — rather than
  by a name prefix, which is the bd `11qv` round-4 (P4) lesson verbatim. Pinned by
  `control_swap_value_reject_arm_cone_cq_call.ll`.
* **F-2 (P2) — RE-PROVED AT THE SOURCE.** The increment falsified a *measured*
  claim in `SwapRouteEmit.cpp`'s cross-region select pre-flight ("a `select` cannot
  satisfy `valueArmIsPureChain`"), whose own retirement trigger demanded a re-proof.
  Re-proved by construction: the `AngleSelectRegion` hazard is now closed by (K5)
  when the angle's consumer is inside the arm and by (K3) when it is outside —
  measured on both binaries, and pinned by
  `control_swap_value_reject_arm_cone_angle_select_{consumer,escape}.ll`.
* **ATTACK D — the reviewer BUILT the shape the increment's record said it could
  not exhibit.** `declineRound2TaintedArmCone` is backtrace-confirmed as the
  predicate that fires. The "not claimed reachable" wording is corrected at **both**
  sites (`TaintSet::ValueArmConeOps` and `IMPL_INC1.md`) in the same change as the
  fixture lands — L7: a record correction not applied to the source is not a
  correction. Pinned by `control_swap_value_reject_arm_cone_round2_quantum.ll`.
  ⚠ The transferable part is *why* it was missed: the probe needs a BLOCK between
  the 6.5 merge and the value region's branch, or the pair declines earlier at bd
  `35t0`'s precedence check — **a probe that reaches the wrong fence first measures
  the wrong fence.**
* **F-3 (P3) — corrected** at `emitValueRegion`'s header, which still said the arm
  holds only the chain with "no memory and no call".
* **F-4 (P3)** — source post-dating the pinned binary. Resolved by rebuilding and
  proving SUBJECT-A ≡ SUBJECT-B over all 2117 fixtures (above).
* **F-5 (P3)** — this file, and `probes/`, are the answer.
* **F-6 (P3) — FIXED.** The harness's decline-message pattern was
  `cq [a-z]* lowering: …`, which cannot match `cq taint escape: …`, so a
  decline→decline string move in that family scored `SAME`. Now `error:.*`.
* **F-7 (P3) — FILED, not fixed** (bd below): the **if/else two-cone** shape is
  byte-identical to its twin only at the GATE STREAM, not the whole function body,
  and no fixture pins it.
* **F-8 (P3)** — accepted as written; safe direction, not reproduced.

⚠ **THE ROUND RAN NO SUITE, NO REBUILD AND NO LIT, BY INSTRUCTION**, and swept 872
of 2117 fixtures rather than all of them. Its own "WHAT I DID NOT DO" section lists
13 items and is the boundary of this clearance — read it, not this summary.

## Counts at close (re-measured, not quoted)

| quantity | value | was (2026-09-21) |
|---|---|---|
| ctest entries | **473** | 472 |
| `^e2e-` | **463** | 462 |
| `^e2e-slice-` | **405** | 404 |
| `twin-identical` | **44** | 44 (unchanged) |
| `ls ir-pass/test/*.ll` | **2121** | 2112 |
| `ls tests/e2e/*.expected.log` | **407** | 406 |
| twin matrix | **312** + **70** = 382 | unchanged |

⚠ Unlike the previous landing, the fixture delta **is** the whole change: **no existing fixture was
re-derived**, and nothing changed verdict except the two files the increment adds.
