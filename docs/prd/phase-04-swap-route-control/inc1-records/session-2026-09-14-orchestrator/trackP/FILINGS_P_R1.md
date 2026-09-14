# Track P — filings owed to the ORCHESTRATOR after Rule-13 round 1

⚠ **No `bd` record was created or edited from this worktree** (the tracker is a shared Dolt DB and
several tracks are in flight — the orchestrator files). Each item below is stated with the measurement
that makes it filable verbatim. Every verdict is a fact about **`cq-opt`
`283e3b3322a9a94c206eb94471e519e5c9e4ffd60c0917743519ae895a0b2daf`** (SUBJECT, the round-1 binary,
**unchanged by the round-1 fix**) and **`f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`**
(the frozen ORACLE).

---

## FILING 1 (F-P1-6) — OVER-DECLINE: the in-loop φ PHASE kickback, where the in-loop φ SELECT accepts

**Type:** over-decline (a defect to remove — owner ruling 2026-09-11: *"our end-goal is to not decline any
code that will lead to a valid quantum circuit"*). **Not** a Prime-Directive proof, and **not** a
correctness risk: both binaries decline, so nothing is mis-lowered.

**The probe** (`review_r1_probes/r21_inloop_phi_kickback.c`, reproduced independently at the fix tip):

```c
#include "CQ.h"
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }     /* the PREP — OUTSIDE the loop */
    for (int i = 0; i < 3; ++i) {
        if (b1) cq_phi(0.3);                /* the KICKBACK — INSIDE it */
    }
    return cq_measure(b0) + cq_measure(b1);
}
```

**Measured, same stage-1 file through both binaries:**

```
SUBJECT : /tmp/…/r21.c:10:13 … cq controlled lowering: condition predates a non-diagonal gate …   exit 1
ORACLE  : /tmp/…/r21.c:10:13 … cq controlled lowering: branch phase on a bare i1 condition …      exit 1
```

**The string moves; the disposition does not.** Its SELECT twin is a **shipped ACCEPT** —
`ir-pass/test/control_swap_accept_select_mergephi_inloop_outside_prep.ll`, verified `exit 0` on the same
binary — so the asymmetry is between two consumers of the *same* leaf grammar, not between two programs.

**Why it matters beyond tidiness:** this is the shape a **rolled Grover phase kickback on a
bool-controlled prep** takes. It therefore belongs beside bd `wx8g` (whose cost CLAUDE.md already calls
*total*: "Grover as a rolled loop with a bool-controlled rotation or prep compiles in NO spelling on ANY
binary") rather than as a line inside `IMPL_P.md` §9.1.

**Family:** the same `condWireDisposition` cross-block prong as §9.1's named over-decline (a φ leaf
outside the kickback's own `Pred`).

⚠ **The fix is NOT dropping the in-`Pred` conjunct** — `IMPL_P.md` §9.1 says why, and that warning is
load-bearing. It is the CFG-bounded scan (every block on a path from the φ's block to `Pred`, visited-set
bounded), which is a NEW WALK: it needs its own Rule-12 probe family and its own Rule-13 round.

**Suggested bead body:** *"In-loop φ PHASE kickback over an outside prep declines
`condition predates a non-diagonal gate` while the in-loop φ DATA SELECT over the same prep is a shipped
accept. Probe `r21`. Fix = the CFG-bounded positional scan (§9.1), not the removal of the in-`Pred`
conjunct. Blocks a rolled Grover phase kickback."*

---

## FILING 2 (F-P1-2 residual) — three φ-anchored diagnostics with an unusable source location

**Type:** hygiene / Rule 1 diagnostic quality. **All three are PRE-EXISTING** — byte-identical on both
binaries, so none is Track P's regression — and **all three are OUTSIDE `classifyPhaseKickback`**, where
the `PhiAnchor` repair is complete (round 1 enumerated all 24 `diagnoseUnderControl` sites in that
function). Measured with `-g`-compiled `.c` probes:

| probe | shape | message | location |
|---|---|---|---|
| `r12` | `if (b1) cq_phi(.3); else cq_phi(.7);` on a prep φ; `-O1` folds it to a `select` on the ANGLE with **no `!dbg`**, and `classifyAngleSelect` anchors there | `rotation angle` | **`<unknown>:0:0`** |
| `r16` | the in-place-ARM φ (Track M's pinned F-M3) — refused by `classifyArms`, anchored on a **line-0** φ | `control flow` | **`r16_inplace_arm_phi.c:0:0`** |
| `r22` | a kickback and a data select `-O1`-fused on ONE prep φ | `control flow` | **`…c:0:0`** |

⚠ **Two facts the fix should be built on, both new in round 1:**

1. **A merge φ can carry a `!dbg` whose `DILocation` LINE IS 0**, not only no `!dbg` at all. A repair that
   tests `Cond->getDebugLoc()` for null fixes half the class; the `PhiAnchor` pattern (never read the φ's
   location — use the terminator) fixes both.
2. **No hand-written `.ll` fixture in this tree can EVER pin a diagnostic's location.** `ir-pass/test`
   carries no debug info, so all 1947 fixtures report `<unknown>:0:0` whether the anchor is right or
   wrong. The only instrument that can see a location is a **`-g`-compiled `.c` probe whose FULL STDERR is
   byte-compared** against the oracle's. That is why the original `<unknown>:0:0` regression (F-P2)
   survived a green 1946-fixture `ir-pass-lit`, a 0-MISSED injection matrix and a byte-identical
   288-fixture family, and it is why `IMPL_P.md` row 14's *"identical on both binaries"* was weak evidence
   — it had been measured with `.ll` probes (`d_angle`, `d_angle_ry`).

**Also filed with it, reachability UNPROVEN in both directions:** `lowerControlRegions`' `declineRegion`
anchors on `dyn_cast_or_null<Instruction>(A.Condition)`. Before this increment the only region kind whose
`Condition` could be a φ was `SelectRegion`, which the alias pre-flight cannot see (null block fields); a
φ-conditioned **`PhaseKickback` has real block fields**, so if `sequentialChainAlias` ever refuses one the
module declines at line 0. Round 1 could not construct that shape and **does not claim it is
unreachable** — only that **the population is new**.

---

## FILING 3 (F-P1-5 residual) — the LOUD form of the `reverifyRailCondReads` third case

**Type:** defence in depth, gated on a reachable input existing. **Closed in round 1 as an EXPLICIT third
case** (comments in `TaintPropagation.h`'s `RailCondReads` block, at `ArmClassify.cpp`'s `continue`, and
at `CondTreeEmit.cpp`'s `record` lambda), **not** as a loud decline. The reason is on the record so the
decision can be reversed on evidence rather than re-argued:

* the case is **unreachable from any input** — rung 0 admits a φ only as some `BranchRegion`'s committed
  `InPlaceRotation` `Merge`; that region's `emitInPlaceRotationRegion` always runs (every `return` in it
  is preceded by a `diagnoseUnderControl`, which EXITS on the first `DS_Error`, bd `br4a`; its one
  structurally silent path `!CondI && !MergePhi` cannot occur for a `BranchRegion`); M-β then RAUWs the φ
  to the hoisted `cq_theta_i1` call and the record's `WeakTrackingVH` follows the RAUW;
* therefore **no fixture can reach the new decline string**, and an unmirrored decline string is itself a
  defect class this project names (Rule 12(b)/(c));
* and a loud guard would have **moved the binary out from under round 1's clearance** for zero reachable
  benefit.

**RETIREMENT TRIGGER — file it with the bead, because this is the part that decays:** the day ANY emitter
can record a non-`CallInst` control read whose value is **not** subsequently RAUW'd to a `cq_theta_*`
call — a second φ-recording emitter, a `BranchRegion` `return` in `emitInPlaceRotationRegion` that is not
preceded by a diagnostic, or a host driver whose diagnostic handler RETURNS instead of exiting — this
record names a live register whose ladder is **never re-asked, silently**. At that moment case (3) must
become a LOUD decline, and it will then be fixturable.

---

## NOT a filing — recorded so the F-M1 cycle argument is read against it

`r22`: a kickback and a data select on ONE prep φ **DECLINES**, pre-existing and identical on both
binaries, because `-O1` fuses them into a single region carrying both a phase gate and a value merge φ,
and `MergePhiPeel`'s **≥2-φ entry gate does not fire** on a merge with exactly one φ. The three-region
chain (kickback → prep → select) that `IMPL_P.md` §5 describes is therefore reachable only in the
spellings `-O1` declines to fuse.

## NOT a filing — for the merge-and-gate agent's information

Round 1 ran the **L8 duplicate-body scan** on this branch (sha-256 over each fixture's non-comment,
non-blank lines, 1946 files at `98951fa1`): **9 duplicate-body groups, none of them a `mergephi`
fixture** — the `git mv` of `control_swap_reject_select_mergephi_tree_leaf.ll` → `…accept…` is clean and
this branch carries no resurrection risk of its own. The 9 groups are pre-existing and at least two look
deliberate; they are listed in `IMPL_P.md` §7.5. **The scan is still owed AFTER the merge**, on the merged
tree — that is where a resurrection would appear.
