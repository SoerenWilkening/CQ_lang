// ArmClassify.cpp — Per-arm lineage classification + §3c provenance walk.
// See ArmClassify.h for the contract and swap-route 4.1 IMPLEMENTATION §3.
//
// All analysis is by SSA-value identity, before any mutation (Rule 9). The
// classifier walks each arm's contribution to the merge `φ` back along its
// PHASE spine (the chain of `cq_phi`/Rz handle edges); the value the spine
// bottoms at decides the arm's class:
//   * a leaf handle (a value defined OUTSIDE the arm — including a PRE-REGION
//     `cq_phi`, the live DERIVED base — or a `cq_theta` source) →
//     pure phase arm — accept iff that handle is tainted (criterion 3);
//   * an arm-local value-changing op (add/mul/…/non-rotation) → a value arm —
//     §3c PERMANENT reject if it rewrites a register in the condition's
//     transitive taint provenance, else a 4.2 value-arm decline.

#include "ArmClassify.h"

#include "ControlPlan.h"
#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

bool isCallToPrefix(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *F = CI->getCalledFunction();
  return F && F->getName().starts_with(Prefix);
}

bool isPhiCall(const Value *V) { return isCallToPrefix(V, "cq_phi_"); }
bool isThetaCall(const Value *V) { return isCallToPrefix(V, "cq_theta_"); }

// Walk the PHASE spine WITHIN one arm block: while `V` is a `cq_phi` (Rz) call
// DEFINED IN `ArmBB`, follow its arg-0 handle operand (arg 1 is the classical
// angle). Returns the first value the chain bottoms at — the arm's base handle, a
// value-changing op, OR a `cq_phi` defined OUTSIDE `ArmBB` (a pre-region rotation,
// i.e. the live DERIVED base handle the arm extends).
//
// Bounding at the arm-block boundary is LOAD-BEARING (not a tidy-up): an
// UNBOUNDED walk hops past a pre-region `cq_phi` all the way to the `cq_theta`
// source, so a derived routed handle (`%qd = cq_phi(%q,·)` before the branch,
// shared by both arm spines) is misread as the theta `%q`. For a diamond that was
// caught downstream (`Base != StraightThrough` → decline); for an if/else, which
// has NO straight-through to compare against, both arms appeared to bottom at the
// same theta and the region was ACCEPTED, then the emitter collected the shared
// pre-region phi ONCE PER ARM → double-erase SIGSEGV (verify-clean over-accept;
// §8 adversarial review 2026-06-09, reproduced as exit 139). A `cq_phi` surfaced
// as a base here is the live DERIVED base handle — the caller routes it like any
// other tainted leaf (test_C_libtooling-9hh, 2026-06-10; criterion 3 permits a
// derived tainted base).
Value *walkPhaseSpine(Value *V, const BasicBlock *ArmBB) {
  while (auto *CI = dyn_cast<CallInst>(V)) {
    const Function *F = CI->getCalledFunction();
    if (!F || !F->getName().starts_with("cq_phi_") || CI->arg_size() < 1)
      break;
    if (CI->getParent() != ArmBB)
      break;  // pre-region cq_phi — the derived base handle, not an arm gate.
    V = CI->getArgOperand(0);
  }
  return V;
}

// PURE ARM BODY (Rule 8 linearity + no stray ops). The arm block must contain
// NOTHING beyond the linear phase spine that feeds the merge phi — i.e. every
// non-terminator instruction in `ArmBB` is a `cq_phi` on the spine of
// `ArmIncoming`. One check that rejects two distinct silent-miscompile/crash
// paths the swap-route emitter cannot handle (both confirmed by the WI-2 §8
// adversarial review, 2026-06-09):
//   * FAN-OUT — a spine `cq_phi` reused by a sibling `cq_phi` (Rule 8 linearity).
//     The emitter replays + erases ONLY the merge-feeding spine, so the off-spine
//     sibling dangles in `taint.PhiCalls` → use-after-free when `lowerRotations`
//     re-reads its freed operand (reproduced as a broken module).
//   * STRAY op in the arm — a `cq_measure` / `cq_theta` / arithmetic the emitter
//     neither replays nor scrubs. `RegionFlatten` erases the arm BLOCK, so the
//     stray op is silently DROPPED from the IR (e.g. a user measurement vanishes)
//     AND its `taint.MeasureCalls`/`ThetaCalls` pointer dangles → use-after-free
//     in `lowerMeasures`/`lowerRotations`.
// Whole-chain reversal needs linear lineage and a self-contained arm; anything
// else is declined loudly (over-decline is safe; Prime Directive). The base
// handle the spine bottoms at is NOT in `ArmBB` (it is the live register in the
// pred), so it is correctly never inspected here.
bool armBlockIsPureSpine(const BasicBlock *ArmBB, const Value *ArmIncoming) {
  SmallPtrSet<const Value *, 8> Spine;
  for (const Value *V = ArmIncoming; isPhiCall(V);) {
    Spine.insert(V);
    const auto *CI = cast<CallInst>(V);
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  for (const Instruction &I : *ArmBB) {
    if (I.isTerminator())
      continue;
    if (!Spine.count(&I))
      return false;  // a fan-out sibling or a stray op — not a pure phase arm.
  }
  return true;
}

// Is `Base` a VALUE-changing op (changes the computational-basis value), as
// opposed to a leaf quantum handle? Classified by OPCODE/kind, NEVER by defining
// block — clang -O1 (LICM/sinking/GVN) freely hoists a branch-invariant value op
// out of the arm into a dominating block, so keying on `getParent()` there
// mis-accepts a real data-mux / §3c-clobber arm as a phase leaf (a verify-clean
// silent miscompile; caught by WI-1 adversarial review 2026-06-09). A leaf is a
// `cq_theta` source, a `cq_phi` (Rz) result, a function argument, or a constant;
// ANY other instruction (add/mul/cast/select/non-rotation call/…) defining a new
// value from a quantum operand is value-changing.
//
// `cq_phi` is a leaf BY OPCODE: Rz = diag(1, e^{iθ}) is DIAGONAL, so it preserves
// the computational-basis value no matter which block clang placed it in — the
// block-position trap above cannot arise for it (and `-O1` never hoists an
// opaque external `cq_*` call anyway). The arm-bounded spine walk consumed every
// IN-arm `cq_phi` before this is consulted, so one reaching here is a PRE-REGION
// rotation: the live DERIVED base handle the arm extends
// (test_C_libtooling-9hh; §0 criterion 3 permits a derived tainted base).
bool isValueChangingOp(const Value *Base) {
  const auto *I = dyn_cast<Instruction>(Base);
  if (!I)
    return false;  // Argument / Constant — a leaf base.
  if (isThetaCall(I))
    return false;  // quantum source — a leaf handle.
  if (isPhiCall(I))
    return false;  // pre-region Rz — diagonal: the live DERIVED leaf handle.
  return true;     // any other instruction defines a new basis value → decline.
}

// Backward taint provenance of the branch condition: every tainted value
// reachable by walking operand edges back from `Cond`, stopping at `cq_theta`
// sources. Replicates the per-use arg-1 angle exclusion from
// TaintPropagation.cpp VERBATIM — the angle operand of a `cq_phi` is classical
// and must never be collected as a condition operand (the f64/angle miscompile
// family). Only tainted values are recorded; classical scaffolding (constants,
// the classical seed of a theta) is traversed-through but never collected.
void condProvenance(Value *Cond, TaintSet &Taint,
                    SmallPtrSetImpl<Value *> &Out) {
  SmallVector<Value *, 16> Work;
  SmallPtrSet<Value *, 16> Seen;
  Work.push_back(Cond);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    if (Taint.Tainted.count(V))
      Out.insert(V);
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;
    if (isThetaCall(I))
      continue;  // source: collected V already; do NOT enter the classical seed.
    const bool IsPhi = isPhiCall(I);
    for (unsigned Idx = 0, E = I->getNumOperands(); Idx < E; ++Idx) {
      Value *Op = I->getOperand(Idx);
      if (IsPhi) {
        // arg-1 angle exclusion (TaintPropagation.cpp): skip the operand-use
        // that is ONLY the angle (arg 1) and not also the arg-0 handle.
        auto *CI = cast<CallInst>(I);
        if (CI->arg_size() >= 2 && Op == CI->getArgOperand(1) &&
            Op != CI->getArgOperand(0))
          continue;
      }
      Work.push_back(Op);
    }
  }
}

// Does `Base`'s value lineage transitively read a register in `Prov`? Used only
// for the if/else value-arm fallback (a diamond uses the straight-through
// incoming directly). Conservative — stops at `cq_theta` sources.
bool readsProvenance(Value *Base, const SmallPtrSetImpl<Value *> &Prov) {
  SmallVector<Value *, 16> Work;
  SmallPtrSet<Value *, 16> Seen;
  Work.push_back(Base);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    if (Prov.count(V))
      return true;
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;
    if (isThetaCall(I))
      continue;
    for (Value *Op : I->operands())
      Work.push_back(Op);
  }
  return false;
}

// An instruction to anchor a generic decline diagnostic on (for the !dbg /
// source location). Prefer the tainted condition; fall back to the merge phi.
Instruction *declAnchor(const ControlRegion &R) {
  if (auto *I = dyn_cast_or_null<Instruction>(R.Condition))
    return I;
  return R.Merge;
}

// The first rotation whose arg-1 ANGLE operand is TAINTED — i.e. quantum-derived
// data in the angle slot — among the arm's IN-BLOCK spine gates and (for a
// derived base) the pre-region base `cq_phi` itself. Null if every angle is
// classical. The emitter replays each spine gate's angle operand VERBATIM onto
// the rail (`cqrt_rz(rail, angle)`), and nothing downstream lowers a tainted
// non-template angle producer — after rotation lowering's RAUW it reads the i32
// RUNTIME HANDLE, a fixed per-run tag, while the source semantics
// (angle = f(quantum value), value in superposition) admit NO fixed unitary.
// That is a verify-clean silent miscompile (found by the test_C_libtooling-9hh
// §8 adversarial review, 2026-06-10 — probe: `%ang = call double @ext(i32 %qd)`
// in the pred, arm gate `cq_phi(%qd, %ang)`; the lowered trace prints
// `cqrt_rz(rail, ext(handle_id))`). The only sound disposition is a loud
// decline — the angle-classicality precondition is the criterion-3 parallel for
// arg-1 (Rule 3: the angle operand is classical, per-operand-use).
CallInst *taintedAngleGate(Value *ArmIncoming, const BasicBlock *ArmBB,
                           Value *Base, TaintSet &Taint) {
  auto AngleTainted = [&Taint](CallInst *CI) {
    return CI->arg_size() >= 2 && Taint.Tainted.count(CI->getArgOperand(1));
  };
  for (Value *V = ArmIncoming; isPhiCall(V);) {
    auto *CI = cast<CallInst>(V);
    if (CI->getParent() != ArmBB)
      break;  // pre-region — handled via Base below.
    if (AngleTainted(CI))
      return CI;
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  // A derived base's OWN angle must be classical too: declining here turns the
  // later broken-module abort (rotation lowering RAUWs the f64 angle to an i32
  // handle inside a call that is never erased — exit 134) into a clean,
  // source-located decline.
  if (isPhiCall(Base) && AngleTainted(cast<CallInst>(Base)))
    return cast<CallInst>(Base);
  return nullptr;
}

// Does a TAINTED-OPERAND `cq_theta` (an IN-PLACE, NON-DIAGONAL Ry on an existing
// handle) sit between the condition compare and the branch? The emitter mints
// the flag at the BRANCH position, so the flag reads the basis AFTER any gate
// between the compare and the branch. A diagonal gate (`cq_phi`/Rz) preserves
// the basis, so the mint still equals the source compare (the stale-condition
// accept's soundness). A chained Ry does NOT: the flag then encodes a predicate
// of the post-Ry state — the wrong arm fires AND `icmp_inv` cannot strip the
// flag (verify-clean miscompile, pre-existing at WI-3, confirmed by independent
// statevector probe 2026-06-10: overlap 0.853, residual flag P=0.118). Decline
// conservatively: any tainted-operand theta between compare and branch (even on
// another wire — over-decline is safe), or a compare we cannot bound the scan
// for (defined outside the pred block). The principled fix — minting the flag
// at the COMPARE's program point — is deferred (see the bd follow-up issue).
bool nonDiagonalGateBeforeBranch(const ControlRegion &R, TaintSet &Taint) {
  auto *Cond = dyn_cast_or_null<Instruction>(R.Condition);
  if (!Cond || !R.Pred)
    return true;  // cannot reason about the gap — decline (Prime Directive).
  if (Cond->getParent() != R.Pred)
    return true;  // unbounded gap across blocks — conservative decline.
  const Instruction *BI = R.Pred->getTerminator();
  for (const Instruction *I = Cond->getNextNode(); I && I != BI;
       I = I->getNextNode()) {
    const auto *CI = dyn_cast<CallInst>(I);
    if (!CI)
      continue;
    const Function *F = CI->getCalledFunction();
    if (F && F->getName().starts_with("cq_theta_") && CI->arg_size() >= 1 &&
        Taint.Tainted.count(CI->getArgOperand(0)))
      return true;  // chained Ry on a live handle after the compare.
  }
  return false;
}

}  // namespace

ArmDisposition classifyArms(const ControlRegion &Region, TaintSet &Taint) {
  auto *MergePhi = dyn_cast_or_null<PHINode>(Region.Merge);
  if (!MergePhi) {
    diagnoseUnderControl(declAnchor(Region), "control flow");
    return ArmDisposition::Declined;
  }

  // The flag is minted from a SINGLE comparison (icmp/fcmp → `_hl` template). A
  // compound condition (clang's `select i1` for `&&`/`||`) or any non-compare i1
  // is not a 4.1-lowerable region — decline (closes the compound-cond
  // over-accept; WI-1 adversarial review 2026-06-09).
  if (!isa<CmpInst>(Region.Condition)) {
    diagnoseUnderControl(declAnchor(Region), "control flow");
    return ArmDisposition::Declined;
  }

  // The condition compare must feed ONLY the branch. If it is ALSO in a data
  // position (e.g. `c = icmp …; zext c; br c` — clang CSE of a reused `q>5`), the
  // swap-route emitter mints a control flag from it but does NOT consume the
  // compare; once the emitter erases the `br`, the data-position gate that kept
  // `OpcodeLowering` off it is gone, so `OpcodeLowering` mints a SECOND flag for
  // the same condition — two distinct flag handles for one logical condition, a
  // verify-clean wrong-unitary (the route and the data use are then controlled by
  // different physical flags). Decline (Prime Directive). Confirmed by the WI-2
  // §8 adversarial review (2026-06-09).
  for (const User *U : Region.Condition->users())
    if (!isa<BranchInst>(U)) {
      diagnoseUnderControl(declAnchor(Region), "condition used outside the branch");
      return ArmDisposition::Declined;
    }

  // The flag is minted at the BRANCH; a tainted-operand `cq_theta` (non-diagonal
  // Ry) between the compare and the branch makes that mint read a different
  // basis than the source compare — the wrong arm fires and the flag cannot be
  // stripped. Decline (see nonDiagonalGateBeforeBranch).
  if (nonDiagonalGateBeforeBranch(Region, Taint)) {
    diagnoseUnderControl(declAnchor(Region),
                         "condition predates a non-diagonal gate");
    return ArmDisposition::Declined;
  }

  SmallPtrSet<Value *, 16> Prov;
  condProvenance(Region.Condition, Taint, Prov);

  // The diamond's straight-through (Pred-edge) incoming — the muxed variable's
  // prior value AND the handle a phase arm must route. Present only for a
  // diamond; an if/else has no Pred incoming (its routed handle is anchored on
  // the first arm's spine base below).
  Value *StraightThrough = nullptr;
  if (Region.Pred && MergePhi->getBasicBlockIndex(Region.Pred) >= 0)
    StraightThrough = MergePhi->getIncomingValueForBlock(Region.Pred);

  SmallVector<BasicBlock *, 2> Arms;
  if (Region.Arm)
    Arms.push_back(Region.Arm);
  if (Region.ArmFalse)
    Arms.push_back(Region.ArmFalse);

  // The single handle EVERY phase arm must rotate (and that the emitter routes):
  // the diamond's straight-through incoming, or — for an if/else — the base the
  // first arm's phase spine bottoms at. An arm whose spine hits a value-changing
  // op, or bottoms at a DIFFERENT handle / a fresh `cq_theta` source, is not a
  // pure phase arm over the routed handle (closes the cross-handle / new-source
  // / hoisted-value-op mis-accepts; WI-1 adversarial review 2026-06-09).
  Value *Routed = StraightThrough;

  for (BasicBlock *ArmBB : Arms) {
    if (MergePhi->getBasicBlockIndex(ArmBB) < 0) {
      // Arm block does not feed the merge phi — off-pattern shape.
      diagnoseUnderControl(declAnchor(Region), "control flow");
      return ArmDisposition::Declined;
    }
    Value *ArmIncoming = MergePhi->getIncomingValueForBlock(ArmBB);
    Value *Base = walkPhaseSpine(ArmIncoming, ArmBB);

    // Every angle on the arm spine (and a derived base's own angle) must be
    // CLASSICAL — quantum-derived data in the angle slot has no fixed unitary
    // and the emitter would replay it as a handle tag (see taintedAngleGate; the
    // §8 adversarial probe family for test_C_libtooling-9hh).
    if (CallInst *Bad = taintedAngleGate(ArmIncoming, ArmBB, Base, Taint)) {
      diagnoseUnderControl(Bad, "rotation angle");
      return ArmDisposition::Declined;
    }

    // A `cq_phi` surfaced as the in-block base is a PRE-REGION rotation: the arm
    // rotates a DERIVED handle (`%qd = cq_phi(%q,·)` before the branch). That is
    // a legitimate routed base (test_C_libtooling-9hh, 2026-06-10): %qd is
    // tainted with theta lineage (criterion 3), Rz is diagonal so the flag
    // minted from icmp(q) stays recoverable by icmp_inv(q), and rotation
    // lowering RAUWs %q and %qd to the SAME i32 handle — routing the live SSA
    // register is exactly what the emitter does for an un-derived base. It flows
    // through the leaf paths below (isValueChangingOp treats `cq_phi` as a
    // leaf); the WI-3 crash family stays foreclosed by the arm-block-bounded
    // walks here and in SwapRouteEmit (the shared pre-region phi is never
    // collected as an arm gate, so it cannot be double-erased — see
    // [[swap-route-ifelse-derived-base-boundary]]).

    // Pure phase chain bottoming at the routed handle: accept this arm. The
    // routed handle MAY itself be a value DERIVED before the region (an earlier
    // `add`/cast, or the pre-region `cq_phi` above) — that is fine; only a value
    // op ON THE ARM SPINE (i.e. Base != Routed) is a value/permutation arm.
    // Criterion 3: the routed handle must be a tainted quantum handle
    // (control_tainted_diag.ll's classical %y0 is not).
    if (Routed && Base == Routed) {
      if (!Taint.Tainted.count(Base)) {
        diagnoseUnderControl(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;
      }
      if (!armBlockIsPureSpine(ArmBB, ArmIncoming)) {
        diagnoseUnderControl(declAnchor(Region), "impure phase arm");
        return ArmDisposition::Declined;
      }
      continue;
    }

    // If/else first arm: anchor the routed handle on a LEAF spine base (a value
    // op as the first arm's base is a value arm, handled below).
    if (!Routed && !isValueChangingOp(Base)) {
      if (!Taint.Tainted.count(Base)) {
        diagnoseUnderControl(declAnchor(Region), "control flow");
        return ArmDisposition::Declined;
      }
      if (!armBlockIsPureSpine(ArmBB, ArmIncoming)) {
        diagnoseUnderControl(declAnchor(Region), "impure phase arm");
        return ArmDisposition::Declined;
      }
      Routed = Base;
      continue;
    }

    if (isValueChangingOp(Base)) {
      // Value/permutation arm. §3c iff it rewrites the muxed condition operand:
      // for a diamond the muxed variable is the straight-through incoming; for
      // an if/else fall back to a backward provenance read of the arm's value.
      const bool Clobber = StraightThrough ? Prov.count(StraightThrough) != 0
                                           : readsProvenance(Base, Prov);
      diagnoseUnderControl(cast<Instruction>(Base),
                           Clobber ? "arm rewrites a condition operand"
                                   : "value-arm swap-route");
      return ArmDisposition::Declined;
    }

    // A leaf base that is NOT the routed handle: a cross-handle multiplexer or a
    // fresh quantum source muxed against the routed slot — not a phase arm over
    // the routed handle. Decline (over-decline is safe; Prime Directive).
    diagnoseUnderControl(declAnchor(Region), "control flow");
    return ArmDisposition::Declined;
  }

  return ArmDisposition::Accept;
}

}  // namespace cq
