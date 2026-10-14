// ArmClassify.h — Per-arm lineage classification for tainted-condition regions.
//
// Given a shape-recovered `ControlRegion` (from `ControlDetect::recoverRegion`),
// classify every arm's contribution to the merge `φ` (4.2, PRD Part II §8.3 +
// IMPLEMENTATION-4.2 §3 — pure analysis, NO IR mutated, Rule 9):
//
//   * PHASE arm — a pure `@cq_phi_<sfx>` spine (4.1 §0 criteria 2+3): only the
//     retired register form or an EMPTY arm; a register-free `cq_phi(θ)` arm is
//     pre-peeled by `classifyPhaseKickback`.
//   * VALUE arm — a pure LINEAR chain of supported tainted integer
//     `BinaryOperator`s bottoming at exactly the routed slot (base-identity),
//     each link consuming the threaded value as its sole tainted operand.
//     Routable + `Routed ∈ condProvenance` is the §3c PERMANENT reject (ACTIVE
//     since 4.2 WI-3); routable + disjoint is the accept class — a value
//     DIAMOND (WI-4) or a two-arm value IF/ELSE over ONE shared routed base
//     (WI-5), with the ordered chain recorded in `Shadow`/`ShadowFalse` +
//     `ClassArm`/`ClassArmFalse` for `emitValueRegion` (controlled-copy merge).
//   * Everything else declines loudly with its precise string: `ChainBase !=
//     Routed` mux shapes (the Defect-2 fix) and FP-typed merges → `control
//     flow`; mixed phase/value content (either stacking order, or
//     heterogeneous if/else arms) → `mixed phase/value arm`; fan-out / stray
//     ops → `impure value arm`; Q+Q links → `value-arm swap-route` (defer).
//
// The §3c provenance walk replicates the per-use angle exclusion from
// `TaintPropagation.cpp` verbatim (a rotation angle is classical and is never a
// condition operand — the f64/angle family). See swap-route 4.1 IMPLEMENTATION §3.

#ifndef CQ_IRPASS_ARM_CLASSIFY_H_
#define CQ_IRPASS_ARM_CLASSIFY_H_

#include "llvm/ADT/SmallPtrSet.h"  // SmallPtrSetImpl (bd dm7f.52 ClaimedSelects)

namespace llvm {
class Instruction;
class CallBase;
class DominatorTree;
class LoopInfo;
}  // namespace llvm

namespace cq {

struct ControlPlan;
struct ControlRegion;
struct TaintSet;

// Outcome of classifying every arm of a recovered region.
//   * Accept   — every arm is a pure phase chain over a tainted quantum handle
//                (the §0 accept criteria 2 and 3 both hold), OR every arm is a
//                routable value chain over ONE shared tainted routed base
//                disjoint from the condition's provenance (the 4.2 §0
//                criterion; diamond since WI-4, if/else since WI-5), OR every
//                arm is an in-place controlled-Ry arm (`ArmClass::
//                InPlaceRotation`, bd drbq Inc 1: one `cq_theta` on a register
//                disjoint from the condition wire, recorded in `Shadow`/
//                `ShadowFalse` and lowered as `cqrt_ry_<W>_controlled`). NO
//                diagnostic was fired; the caller pushes the region for
//                emission.
//   * Declined — some arm failed a criterion; `classifyArms` has ALREADY fired
//                the precise loud diagnostic (§3c clobber / mux / mixed /
//                impure / QQ-defer / non-quantum base). The caller must lower
//                nothing for this region.
enum class ArmDisposition { Accept, Declined };

// Classify every arm of `Region` (a recovered diamond or if/else). Reads
// `Region.Merge` (the merge `PHINode`), `Region.Arm`/`Region.ArmFalse` (the arm
// blocks), `Region.Pred` (for the diamond straight-through incoming), and
// `Region.Condition`; WRITES `Region.ClassArm`/`ClassArmFalse` and the ordered
// value-chain links into `Region.Shadow`/`ShadowFalse` for a value-class arm
// (pure SSA analysis — no IR is mutated; only the plan struct is populated).
// Fires at most one diagnostic. See `ArmDisposition`.
//
// `DT` is the caller's per-function `DominatorTree`, built ONCE in
// `detectControlRegions` and threaded through (bd test_C_libtooling-lom0 Inc 4).
// It is used for exactly one question — is a non-diagonal gate on the
// condition's wire PROVABLY after the whole emitted stream (`provablyBefore(
// R.Pred->getTerminator(), T, *DT)`)? — and nothing here mutates IR, so the tree
// stays valid for the whole detection sweep (Rule 9: detection is pure analysis
// before any mutation; no block pointer is cached across an erasure because no
// erasure happens during detection). A null `DT` is not an error: it simply
// yields the pre-Inc-4 position-free decline (Prime Directive).
//
// `LI` is the caller's per-function `LoopInfo`, built from the same lazy tree
// (bd test_C_libtooling-drbq Increment 3). It is used for exactly one question —
// R7's LOOP half: is the rotated base's rail carried across `L`'s back edge by a
// header φ the round-2 collapse will actually claim (clauses (b)/(b'), PRD
// §13.2b)? A null `LI` is not an error: it yields the pre-Inc-3 unconditional
// in-loop decline (Prime Directive). Every OTHER loop question this class owes
// was already answered by `ControlDetect::flatRegionRollableInLoop` before
// `Region.InLoop` was set.
//
// bd dm7f.52: `ClaimedSelects` receives every logical `select i1` NODE of an
// accepted compound condition tree (the in-place Ry / state-prep consumer of
// `CondTreeEmit`), exactly as `classifyPhaseKickback` fills it, so the caller's
// tainted-select scan does not ALSO claim the node as an i1 data mux. Null is
// allowed (no select can then be claimed; an accepted tree with a select node
// would be scanned again — every production caller passes the set).
//
// bd dm7f.53: `Plan` (the regions detected so far) lets a compound condition
// tree carry a REGION-MERGE φ leaf (`condTreePhiLeafRefusal` rung 0 asks it);
// null refuses every φ leaf with `control flow`. On accept, the indices of the
// cross-block φ leaves' prep regions are in `Region.PrepRegionIdxs` (emit THIS
// region first — the `PhaseKickback` direction).
ArmDisposition classifyArms(
    ControlRegion &Region, TaintSet &Taint, const llvm::DominatorTree *DT,
    const llvm::LoopInfo *LI,
    llvm::SmallPtrSetImpl<llvm::Instruction *> *ClaimedSelects = nullptr,
    const ControlPlan *Plan = nullptr);

// Outcome of the 6.5 classical-call-arm recognizer (DD-7), tried by
// `ControlDetect::handleBranchRegion` BEFORE `classifyArms`:
//   * Accept        — the §2.13 shape (a tainted-condition diamond whose single
//                     content arm is a PURE CLASSICAL call with all-classical
//                     args whose i32 result feeds the 2-incoming merge). The
//                     caller sets `Region.Kind = ClassicalCallArm` and pushes it
//                     for `ClassicalCallArmEmit`. NO diagnostic fired.
//   * Declined      — structurally a classical-call arm (a direct, non-intrinsic,
//                     classical-result call is the arm's merge incoming) but a
//                     precondition failed (impure callee / tainted argument /
//                     multi-user / unclean arm block). A loud, source-located
//                     diagnostic was fired; lower nothing (Rule 1).
//   * NotApplicable — not this shape at all (the arm incoming is not a direct
//                     classical call, or it is an if/else, or the merge is
//                     malformed). The caller falls through to `classifyArms`
//                     (the phase / value / §3c-clobber classifier), which owns
//                     its own diagnostics.
//
// The fp/i128 RESULT gate is deliberately NOT here — an Accept'd region whose
// merge width has no `cqrt_copy_<W>_controlled` declines at EMIT
// (`copyControlledFn` non-null, the f64-trap gate, DD-7), exactly as
// `SelectMergeEmit` does. §3c (DD-7) is established by the all-non-tainted
// requirement on the result + every arg (the classical-call analog of the select
// §16.6 §3c-vacuity); a value-changing clobber (`q2 = add q, c`) is not a
// direct-call merge incoming and so declines via `classifyArms` instead.
enum class ClassicalCallDisp { Accept, Declined, NotApplicable };

ClassicalCallDisp classifyClassicalCallArm(ControlRegion &Region,
                                           TaintSet &Taint);

// bd 9hea — does argument `Ai` of `Call` need, and admit, a `freeze` at the 6.5
// hoist? True iff the parameter is `noundef`, the argument is NOT provably defined,
// and `freeze` actually DISCHARGES the obligation.
//
// *** THE CLAIM AND THE EMIT SHARE THIS ONE DEFINITION ON PURPOSE. ***
// `classifyClassicalCallArm` uses it to decide whether to accept, and
// `emitClassicalCallArmRegion` uses it to decide what to freeze. If they could
// disagree, the classifier would accept a call the emitter leaves un-frozen, which
// is the UB the clause exists to prevent. Same reason bd q2wk made the phi route's
// claim record what it proved instead of letting emit re-derive it.
//
// *** AND IT MUST BE CALLED BEFORE THE HOIST, AT BOTH SITES (bd iwz1). ***
// `isGuaranteedNotToBeUndefOrPoison` also reasons from USES, and once the call is
// unconditional a `noundef` parameter operand is itself a use-based proof that the
// operand is defined — so re-queried AFTER `Call->moveBefore(BI)` this predicate
// flips 0 -> 1 and the hoisted call SELF-LICENSES the very argument it should have
// refused. Both callers query while the call is still in the arm.
//
// `freeze` yields an ARBITRARY DEFINED value, which discharges `noundef` and nothing
// else — so the attribute test is a WHITELIST: the parameter's attributes must all be
// freeze-inert. `range`/`nonnull`/`align`/`dereferenceable[_or_null]`/`nofpclass` each
// say a POISON value is passed when violated, and an arbitrary defined value can
// violate any of them, which would put poison back in a `noundef` operand. A
// BLACKLIST would silently admit the fifth such attribute LLVM adds — the exact
// failure mode bd s6ao's post-mortem names — so the safe spelling is to enumerate
// what is INERT and refuse everything else (Prime Directive: over-declining is safe).
bool freezeDischargesHoistedArg(const llvm::CallBase *Call, unsigned Ai);

}  // namespace cq

#endif  // CQ_IRPASS_ARM_CLASSIFY_H_
