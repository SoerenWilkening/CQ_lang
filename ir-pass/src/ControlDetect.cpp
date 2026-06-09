// ControlDetect.cpp — Pure-analysis detection of tainted control regions.
//
// Replaces the transitional ControlStub.cpp (loud-decline-only). Owns the
// shared `diagnoseUnderControl` primitive, the `detectControlRegions`
// dispatcher, and the internal `recoverRegion` shape recovery. All recognition
// is by SSA-value identity BEFORE any IR mutation (Rule 9) — it survives the
// later rotation-lowering RAUW-to-handle because no block pointers are cached
// across erasures (none happen here).
//
// WI-1 (detection + §3c reject, NO emission): every tainted-condition
// `br`/`select`/`switch` is recognized and declined with a PRECISE string —
// §3c clobber is a permanent reject; value-arm/nested/select/switch defer to a
// named later increment; a recognized PHASE-arm region declines TRANSITIONALLY
// ("phase-arm swap-route emission pending") so nothing mis-lowers until the
// swap-route emitter lands (WI-2/WI-3). The returned plan is empty.
//
// See swap-route 4.1 IMPLEMENTATION §0/§2/§3.

#include "ControlPlan.h"

#include "ArmClassify.h"
#include "TaintPropagation.h"

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <string>

using namespace llvm;

namespace cq {

// Promoted from ControlStub.cpp:43-48 (now shared via ControlPlan.h). Same
// `DiagnosticInfoUnsupported(DS_Error)` surface + message form, so the "… under
// quantum control" FileCheck idiom still holds and `opt` exits non-zero. The
// offending instruction's `!dbg` is attached so the rejection is source-located.
void diagnoseUnderControl(Instruction *Where, StringRef What) {
  std::string Msg =
      ("cq controlled lowering: " + What + " under quantum control").str();
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

namespace {

// The recognized shape of a tainted-condition `br` region.
enum class RegionShape { Diamond, IfElse, Nested, OffPattern };

// `BB`'s unique successor iff it ends in an UNCONDITIONAL branch; else null.
BasicBlock *uncondSucc(BasicBlock *BB) {
  auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
  return (BI && BI->isUnconditional()) ? BI->getSuccessor(0) : nullptr;
}

// Does `BB` end in a tainted-condition conditional branch? (the nested-control
// signal — an arm that is itself a quantum-controlled region, deferred to 4.3).
bool hasTaintedCondBranch(BasicBlock *BB, TaintSet &Taint) {
  auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
  return BI && BI->isConditional() && Taint.Tainted.count(BI->getCondition());
}

// The sole 2-incoming merge `φ` of block `M`. Null if `M` has not exactly one
// PHINode, or that phi is not 2-incoming (a mixed gate+angle merge, or a
// shared/nested merge with >2 predecessors → decline generic, never mis-lower).
PHINode *soleMergePhi(BasicBlock *M) {
  PHINode *Found = nullptr;
  for (PHINode &P : M->phis()) {
    if (Found)
      return nullptr;  // more than one phi → off-pattern.
    Found = &P;
  }
  if (!Found || Found->getNumIncomingValues() != 2)
    return nullptr;
  return Found;
}

// Recognize the §0 diamond / if-else shape of a tainted-condition `br` by SSA
// identity, populating `R` (Condition/Pred/Arm/ArmFalse/MergeBB/Merge and the
// Rule-9 ArmNegated polarity). Returns the shape, or OffPattern/Nested to
// decline. Never assumes successor 0 is the taken arm.
RegionShape recoverRegion(BranchInst *BI, TaintSet &Taint, ControlRegion &R) {
  BasicBlock *Pred = BI->getParent();
  BasicBlock *S0 = BI->getSuccessor(0);  // cond == true
  BasicBlock *S1 = BI->getSuccessor(1);  // cond == false
  R.Condition = BI->getCondition();
  R.Pred = Pred;
  R.Kind = ControlRegion::BranchRegion;

  // Nested control first: an immediate successor that is itself a
  // tainted-condition branch (the outer/mid arm of `if(q){if(q'){…}}`).
  if (hasTaintedCondBranch(S0, Taint) || hasTaintedCondBranch(S1, Taint))
    return RegionShape::Nested;

  // Diamond, orientation A — arm = S0 (true successor), merge = S1: the arm is
  // single-pred(Pred), single-succ(merge), and the merge is reached directly by
  // the straight-through (false) edge.
  if (uncondSucc(S0) == S1 && S0->getSinglePredecessor() == Pred) {
    if (PHINode *Phi = soleMergePhi(S1))
      if (Phi->getBasicBlockIndex(S0) >= 0 &&
          Phi->getBasicBlockIndex(Pred) >= 0) {
        R.Arm = S0;
        R.MergeBB = S1;
        R.Merge = Phi;
        R.ArmNegated = false;
        return RegionShape::Diamond;
      }
  }
  // Diamond, orientation B — arm = S1 (FALSE successor), merge = S0 (Rule 9:
  // clang -O1 swaps successors for `if(u!=k)`-style conditions). The gate arm
  // fires on ¬flag; record ArmNegated.
  if (uncondSucc(S1) == S0 && S1->getSinglePredecessor() == Pred) {
    if (PHINode *Phi = soleMergePhi(S0))
      if (Phi->getBasicBlockIndex(S1) >= 0 &&
          Phi->getBasicBlockIndex(Pred) >= 0) {
        R.Arm = S1;
        R.MergeBB = S0;
        R.Merge = Phi;
        R.ArmNegated = true;
        return RegionShape::Diamond;
      }
  }
  // If/else — both successors are single-pred(Pred), single-succ arms
  // reconverging at a common merge distinct from either arm.
  if (BasicBlock *M = uncondSucc(S0))
    if (M == uncondSucc(S1) && M != S0 && M != S1 &&
        S0->getSinglePredecessor() == Pred &&
        S1->getSinglePredecessor() == Pred) {
      if (PHINode *Phi = soleMergePhi(M))
        if (Phi->getBasicBlockIndex(S0) >= 0 &&
            Phi->getBasicBlockIndex(S1) >= 0) {
          R.Arm = S0;       // true arm
          R.ArmFalse = S1;  // false arm (¬flag bracket at emit time)
          R.MergeBB = M;
          R.Merge = Phi;
          R.ArmNegated = false;
          return RegionShape::IfElse;
        }
    }

  return RegionShape::OffPattern;
}

// Recognize and classify one tainted-condition `br`, firing the precise
// decline. WI-1 fires a diagnostic for every disposition (no region is pushed).
void handleBranchRegion(BranchInst *BI, TaintSet &Taint) {
  ControlRegion R;
  switch (recoverRegion(BI, Taint, R)) {
  case RegionShape::OffPattern:
    diagnoseUnderControl(BI, "control flow");
    return;
  case RegionShape::Nested:
    diagnoseUnderControl(BI, "nested control flow");
    return;
  case RegionShape::Diamond:
  case RegionShape::IfElse:
    if (classifyArms(R, Taint) == ArmDisposition::Declined)
      return;  // ArmClassify already fired the precise diagnostic (§3c / value).
    // ACCEPT: pure phase arm(s) over a tainted handle. No emitter in WI-1 —
    // decline TRANSITIONALLY so nothing mis-lowers. WI-2 replaces this line
    // with `plan.Regions.push_back(R)` to drive SwapRouteEmit.
    diagnoseUnderControl(BI, "phase-arm swap-route emission pending");
    return;
  }
}

}  // namespace

// Scan every function for a tainted-condition `br i1` / `switch` / `select i1`
// and decline it with the precise string; return an empty `ControlPlan`. A
// classical-condition construct is left byte-untouched (detection keys strictly
// on condition taint). No IR is mutated.
ControlPlan detectControlRegions(Module &M, TaintSet &taint) {
  ControlPlan plan;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      Instruction *Term = BB.getTerminator();
      if (auto *BI = dyn_cast<BranchInst>(Term)) {
        if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
          handleBranchRegion(BI, taint);
      } else if (auto *SI = dyn_cast<SwitchInst>(Term)) {
        if (taint.Tainted.count(SI->getCondition()))
          diagnoseUnderControl(SI, "switch");
      }
      for (Instruction &I : BB)
        if (auto *Sel = dyn_cast<SelectInst>(&I))
          if (taint.Tainted.count(Sel->getCondition()))
            diagnoseUnderControl(Sel, "select");
    }
  }
  return plan;
}

}  // namespace cq
