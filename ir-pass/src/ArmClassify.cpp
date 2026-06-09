// ArmClassify.cpp — Per-arm lineage classification + §3c provenance walk.
// See ArmClassify.h for the contract and swap-route 4.1 IMPLEMENTATION §3.
//
// All analysis is by SSA-value identity, before any mutation (Rule 9). The
// classifier walks each arm's contribution to the merge `φ` back along its
// PHASE spine (the chain of `cq_phi`/Rz handle edges); the value the spine
// bottoms at decides the arm's class:
//   * a leaf handle (a value defined OUTSIDE the arm, or a `cq_theta` source) →
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
// as a base here is declined by the caller (over-decline is safe; routing a
// derived handle is a deferred generalization).
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
// `cq_theta` source, a function argument, or a constant; ANY other instruction
// (add/mul/cast/select/non-rotation call/…) defining a new value from a quantum
// operand is value-changing. The phase spine is walked past `cq_phi` BEFORE this
// is consulted, so a `cq_phi` reaching here is malformed → treated as a value op
// (decline). Note: this does NOT fire for a handle that is merely DERIVED before
// the region — that handle equals the routed `StraightThrough` and is accepted
// by the base-identity short-circuit in `classifyArms`, before this is reached.
bool isValueChangingOp(const Value *Base) {
  const auto *I = dyn_cast<Instruction>(Base);
  if (!I)
    return false;  // Argument / Constant — a leaf base.
  if (isThetaCall(I))
    return false;  // quantum source — a leaf handle.
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

    // A `cq_phi` surfaced as the in-block base is a pre-region rotation — the arm
    // rotates a DERIVED handle (`%qd = cq_phi(%q,·)` before the branch), not a
    // leaf quantum source. WI-3 routes only an un-derived handle, so decline (the
    // derived-handle routing generalization is deferred; over-decline is safe,
    // Prime Directive). This forecloses the if/else over-accept whose emitter
    // double-erased the shared pre-region phi (SIGSEGV) and mis-resolved the
    // routed handle to the stale theta (§8 adversarial review 2026-06-09). The
    // diamond already declined this via `Base != StraightThrough`; the guard keeps
    // it declining (now by an explicit reason) AND covers the if/else, which has
    // no straight-through to compare against. See
    // [[swap-route-ifelse-derived-base-boundary]].
    if (isPhiCall(Base)) {
      diagnoseUnderControl(declAnchor(Region), "control flow");
      return ArmDisposition::Declined;
    }

    // Pure phase chain bottoming at the routed handle: accept this arm. The
    // routed handle MAY itself be a value DERIVED before the region (an earlier
    // `add`/cast) — that is fine; only a value op ON THE ARM SPINE (i.e.
    // Base != Routed) is a value/permutation arm. Criterion 3: the routed handle
    // must be a tainted quantum handle (control_tainted_diag.ll's classical %y0
    // is not).
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
