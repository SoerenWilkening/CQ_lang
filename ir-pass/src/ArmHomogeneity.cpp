// ArmHomogeneity.cpp — Tree-homogeneity gate (IMPLEMENTATION-4.3 §3.2).
// See ArmHomogeneity.h for the contract.
//
// Classifies the two arms of a recovered depth-2 nest (the OUTER arm = the `Mid`
// block, the INNER content arm) as Phase or Value, reusing the de-anonymized
// per-arm lineage walks (ArmAnalysis.h). The accepted shape is ALL-PHASE; any
// value arm declines (`mixed phase/value arm` / `value-arm swap-route`) and a
// stray op in `Mid` declines `impure phase arm`. All pure SSA analysis (Rule 9).

#include "ArmHomogeneity.h"

#include "ArmAnalysis.h"
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

// TU-local intrinsic predicates (the ArmAnalysis.h note: these collide with the
// same-named anon helpers in ArmClassify.cpp / SwapRouteEmit.cpp if promoted).
bool isCallToPrefix(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *F = CI->getCalledFunction();
  return F && F->getName().starts_with(Prefix);
}
// ⚠ VACUOUS SINCE bd test_C_libtooling-3qlq Inc 1 (2026-09-05), AND DELIBERATELY
// KEPT (PRD `retire-swap-route-PRD.md` §6.2 row P6: "every 'Rz is diagonal and
// exempt' clause becomes VACUOUS rather than deleted").
//
// The 15-width `@cq_phi_<sfx>(x, angle)` family is RETIRED: `CQ.h` no longer
// declares it and `resolveSources` no longer resolves it, so no call this
// predicate can match exists in a module the pass lowers. It CANNOT accidentally
// match the register-free replacement, and that is a fact about the strings, not
// a hope: `StringRef("cq_phi").starts_with("cq_phi_")` is FALSE — six characters
// against a seven-character prefix. The new call is recognized by EXACT
// membership instead (`TaintPropagation.h`'s `isRegisterFreePhaseCall`), which is
// also the project's standing accept-side discipline (never a name prefix — the
// `cq_theta_evil` hazard).
//
// KEEPING IT IS THE POINT: a `void(double)` call has no arg-0 WIRE and no arg-1
// ANGLE, so every clause below that follows `getArgOperand(0)` as a rail, or
// reads `getArgOperand(1)` as an angle, would be reading the wrong operand — or
// out of range — if this predicate were widened to admit it. Do not "fix" this by
// making it match `cq_phi`.
bool isPhiCall(const Value *V) { return isCallToPrefix(V, "cq_phi_"); }
bool isThetaCall(const Value *V) { return isCallToPrefix(V, "cq_theta_"); }

// Mirror of ArmClassify.cpp's anonymous `isValueChangingOp` (kept TU-local for
// the same reason): a value the merge carries that is NOT a leaf quantum handle.
// A leaf is a `cq_theta` source, a `cq_phi` (Rz, DIAGONAL — basis-preserving) the
// arm extends, a function argument, or a constant; ANY other instruction
// (add/mul/cast/select/…) defining a new computational-basis value is
// value-changing. Classified by OPCODE, never by defining block (clang -O1 hoists
// branch-invariant ops; keying on getParent() mis-accepts a real mux — the
// verify-clean miscompile WI-1 review caught for the flat path).
bool isValueChangingOp(const Value *Base) {
  const auto *I = dyn_cast<Instruction>(Base);
  if (!I)
    return false;
  if (isThetaCall(I) || isPhiCall(I))
    return false;
  return true;
}

enum class ArmContent { Phase, Value };

// Classify one arm's merge contribution as Phase or Value. Walks the IN-BLOCK
// phase spine (`walkPhaseSpine`); the arm is VALUE iff that spine bottoms at an
// IN-ARM value-changing op (an Rz stacked over a basis the arm itself changed),
// or — when the spine consumed nothing — the arm incoming is itself a
// value-changing op (the value chain `q=q*7; q=q+3`). Otherwise the arm is a
// pure phase chain (possibly empty) over a leaf base. NO emission.
ArmContent classifyArmContent(BasicBlock *ArmBB, Value *ArmIncoming) {
  Value *Base = walkPhaseSpine(ArmIncoming, ArmBB);
  if (Base != ArmIncoming) {
    // The spine consumed ≥1 `cq_phi`; an in-arm value-changing base is the
    // mixed `q=q*7; rz(q)` lineage (treated as value — mixed fires downstream).
    if (auto *BI = dyn_cast<Instruction>(Base);
        BI && BI->getParent() == ArmBB && isValueChangingOp(Base))
      return ArmContent::Value;
    return ArmContent::Phase;
  }
  // The spine consumed nothing: the arm incoming is the base itself (a leaf —
  // empty phase arm) or the top of a value chain (`q=q+3`).
  return isValueChangingOp(Base) ? ArmContent::Value : ArmContent::Phase;
}

// PURE PHASE INNER ARM (the clean-diamond twin of ArmClassify's
// `armBlockIsPureSpine`): every non-terminator instruction in `ArmBB` must lie
// on the linear `cq_phi` spine of `ArmIncoming` — rejecting a fan-out sibling or
// a stray op the emitter would silently drop on flatten (Rule 8 / Rule 5).
bool innerArmIsPureSpine(const BasicBlock *ArmBB, const Value *ArmIncoming) {
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
      return false;
  }
  return true;
}

// PURE PHASE OUTER ARM (the `Mid` carve-out, COMPLETENESS#5). `Mid` legitimately
// holds — beyond its phase-gate spine — the INNER condition compare and the inner
// branch (and, for a derived inner cond, that compare's in-`Mid` operand
// lineage). Every OTHER non-terminator instruction is a stray (a value op, a
// measure, a fan-out sibling) the emitter would drop on flatten → `impure phase
// arm`. The allow-set is: the `cq_phi` spine of `MidIncoming` DOWN TO its base
// (inclusive — a degenerate gate-free Mid bottoms at an in-`Mid` `cq_theta`),
// PLUS `InnerCond` and its operand lineage defined IN `Mid`. The whole-block scan
// is load-bearing: a spine-only walk would silently accept a stray value op
// (verify-clean over-accept / dangling-taint UAF, the round-2 convergence catch).
bool midIsPurePhase(const BasicBlock *Mid, Value *MidIncoming, Value *InnerCond) {
  SmallPtrSet<const Value *, 16> Allowed;
  // Phase spine + the base the spine bottoms at.
  for (Value *V = MidIncoming;;) {
    Allowed.insert(V);
    if (!isPhiCall(V))
      break;
    auto *CI = cast<CallInst>(V);
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  // InnerCond + its transitive operand lineage defined IN Mid (a derived inner
  // cond `icmp(add(%g,1), 9)` has the in-`Mid` `add` as legitimate content).
  SmallVector<const Value *, 8> Work{InnerCond};
  SmallPtrSet<const Value *, 8> Seen;
  while (!Work.empty()) {
    const Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    const auto *I = dyn_cast<Instruction>(V);
    if (!I || I->getParent() != Mid)
      continue;  // out-of-Mid operand (e.g. the routed base in Pred) — not scanned.
    Allowed.insert(I);
    for (const Use &U : I->operands())
      Work.push_back(U.get());
  }
  for (const Instruction &I : *Mid) {
    if (I.isTerminator())
      continue;
    if (!Allowed.count(&I))
      return false;  // a stray op beside the phase spine + inner condition.
  }
  return true;
}

}  // namespace

bool treeHomogeneous(BasicBlock *Mid, Value *MidIncoming, Value *InnerCond,
                     BasicBlock *InnerArm, Value *InnerArmIncoming,
                     TaintSet &Taint, Instruction *Anchor) {
  // Tainted-angle safety (Rule 3) — quantum-derived data in any rotation's angle
  // slot has no fixed unitary; loud decline before any homogeneity verdict.
  {
    Value *MidBase = walkPhaseSpine(MidIncoming, Mid);
    if (CallInst *Bad = taintedAngleGate(MidIncoming, Mid, MidBase, Taint)) {
      diagnoseUnderControl(Bad, "rotation angle");
      return false;
    }
    Value *InnerBase = walkPhaseSpine(InnerArmIncoming, InnerArm);
    if (CallInst *Bad = taintedAngleGate(InnerArmIncoming, InnerArm, InnerBase,
                                         Taint)) {
      diagnoseUnderControl(Bad, "rotation angle");
      return false;
    }
  }

  ArmContent MidClass = classifyArmContent(Mid, MidIncoming);
  ArmContent InnerClass = classifyArmContent(InnerArm, InnerArmIncoming);

  const bool SawPhase =
      MidClass == ArmContent::Phase || InnerClass == ArmContent::Phase;
  const bool SawValue =
      MidClass == ArmContent::Value || InnerClass == ArmContent::Value;

  // Value rows fire BEFORE the per-arm purity scan (FA2 — and before criterion-4
  // RAUW-collapse, which the caller runs only after this returns).
  if (SawValue && SawPhase) {
    diagnoseUnderControl(Anchor, "mixed phase/value arm");
    return false;
  }
  if (SawValue) {  // all-value — the deferred value-nest increment.
    diagnoseUnderControl(Anchor, "value-arm swap-route");
    return false;
  }

  // All-phase: every arm must be a self-contained linear phase spine.
  if (!midIsPurePhase(Mid, MidIncoming, InnerCond) ||
      !innerArmIsPureSpine(InnerArm, InnerArmIncoming)) {
    diagnoseUnderControl(Anchor, "impure phase arm");
    return false;
  }
  return true;
}

}  // namespace cq
