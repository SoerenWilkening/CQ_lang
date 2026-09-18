# Rule-13 ROUND 1 probes — bd `test_C_libtooling-fn1q` increment 2

Authored by the **independent reviewer**, not by the implementer, and committed
verbatim because a round that reports a P1 without its probes is not reproducible
(bd `test_C_libtooling-5zwz`). Verdict: **BLOCKED** — 1 P1, 2 P2, 3 P3.

```
ORACLE      cq-opt 1b396ed08b01b8ecac7…   SUBJECT-v1 a179aba6192dbe963c7b…  (carries the P1)
SUBJECT     cq-opt a0e31e0316496f71a684…  (the fixes)
```

| probe | finding it produced |
|---|---|
| `dead/deadrail_pos.ll` | ⚠ **THE P1.** A rail-conditioned diamond with two all-`false` `i1` merge phis, arm on the FALSE successor. On SUBJECT-v1: `opt` exit **0**, **0 bytes stderr**, and **no `cqrt_alloc_i1`/`cqrt_ry_i1`** — the user's Ry erased by `sweepDead`. `dead/vg.ll` is that output. |
| `dead/deadrail_neg.ll` | the other polarity; reproduces |
| `dead/straightline_deadtheta.ll` (+ `sl.*.ll`) | ⚠ **THE CONTROL THAT MAKES IT A DEFECT.** The SAME dead `cq_theta_i1` with no region at all lowers on BOTH binaries (`alloc_i1=1 ry=2`). The deletion was never a general dead-code policy. |
| `creach2/nomeasure.c`, `creach2/degenerate.c` | the two FAILED attempts at a `-O1` C reproducer (rail stays live / clang folds the region away). ⚠ Read the P1 as IR-level: **reachability from C neither shown nor disproved.** |
| `xorfam/notcond_4.ll` | **P2-1.** `xor %cmp, true` condition, **no rail in the module**: ORACLE exit 1 → SUBJECT-v1 exit 0. Out-of-scope accept widening. |
| `brk.{oracle,subj}.ll` | the addendum: the ONE corpus fixture carrying `xor i1 …, true` (`lowering_loop_break_unsigned.ll`) appears only on `CHECK:` lines and is **stream-identical on both binaries** — so the corpus has **no input module** that can reach the fold that way. L10. |
| `bool/boolalg_railpos.ll` + `bool/twin_allselect.ll` | **P2-2.** The BoolAlg surface and its hand-if-converted twin; **gate streams identical**, twin accepts on the ORACLE. Became the shipped fixture pair. |
| `bool/boolalg_railneg.ll`, `bool/twin_allselect_neg.ll` | the negative polarity — declines on BOTH, and so does its twin. Consistent, left declining. |
| `disc/d1_and.ll`, `disc/d2_bare.ll`, `disc/d2b.ll`, `disc/d3_rail.ll` | **P3-2** discriminator mutants proving each decline fixture pins the boundary it claims. ⚠ The reviewer's first `d2` attempt produced ill-formed IR (`Instruction does not dominate all uses`) — a BAD MUTANT, not a fixture defect; recorded so a reader of the raw log does not misread it. |
| `p5_4var.c`, `p5_2var.c`, `base_2var.c`, `fam/*` | protocol item 5 and its 2-variable control |
| `mut/*` | the injection matrix behind **P3-1** (an injected 9th controlled copy MISSED by all four prefixes) |

## The two sentences worth carrying out of this round

1. **When you replace a STRUCTURAL containment with a predicate, enumerate what the
   structure was holding.** E6's grammar admitted no `CallInst` at all; that is what
   kept CQ's own intrinsics out of `sweepDead`. The rail leaf made one. Increment 1
   learned the identical lesson from `valueArmIsPureChain`'s (K5) **one increment
   earlier, one stage over**.
2. **A ruling written in one stage is not carried to its sibling by being true.**
   `RegionFlatten.cpp:107` had the exact conjunct and the exact reason in writing.
   Nothing propagated it.
