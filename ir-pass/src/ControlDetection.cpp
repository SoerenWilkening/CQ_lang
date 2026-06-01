// ControlDetection.cpp — Pure-analysis recovery of controlled regions from
// the realized `-O1` control surface (PRD §2.2, IMPLEMENTATION §5.1). WP3
// recognizes the `br`-diamond + merge-`φ` shape; WP4 adds the classical-arm
// `select i1` shape; flag conjunctions (WP6) are not built here.
//
// Detection keys STRICTLY on taint membership of the branch condition (§1.3):
// a tainted-condition `br i1` over a 2-block diamond is a controlled region;
// a classical-condition branch has no physical content and is ignored. No IR
// is mutated — the plan is consumed downstream (`RotationLowering` skips the
// in-shadow `cq_phi`; `ControlledLowering` lowers the region). The escape
// guard (ret/measure/out-of-region br in the arm) emits the loud diagnostic
// and skips the region (PRD §5; structural cousin of the prototype's
// `computeFreePoint` ret check).

#include "ControlPlan.h"

#include "TaintPropagation.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <string>

using namespace llvm;

namespace cq {

namespace {

// Loud "unsupported under quantum control" diagnostic, on the same
// `DiagnosticInfoUnsupported(DS_Error)` surface the rest of the pass uses
// (mirrors `diagnoseNoTemplate` / RotationLowering's `diagnoseUnsupported`).
// `What` names the escape so a fixture can FileCheck it.
void diagnoseEscape(Instruction *Where, StringRef What) {
  std::string Msg =
      ("cq controlled lowering: " + What + " under quantum control").str();
  Where->getFunction()->getContext().diagnose(
      DiagnosticInfoUnsupported(*Where->getFunction(), Msg));
}

// A `@cq_measure_<sfx>` (front-end) or `@cqrt_measure_<W>` (already lowered)
// call — measurement collapses the controlled state and is an escape. Detection
// runs before measure lowering so only the `cq_measure_` form is live, but
// accepting both keeps the rule honest.
bool isMeasureCall(const Instruction &I) {
  const auto *CI = dyn_cast<CallInst>(&I);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return N.starts_with("cq_measure_") || N.starts_with("cqrt_measure_");
}

// A `@cq_phi_<sfx>` gate-body call (the in-shadow op WP3 lowers controlled).
bool isPhiCall(const Instruction &I) {
  const auto *CI = dyn_cast<CallInst>(&I);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cq_phi_");
}

// Scan the single guarded arm `Arm` for an escape (PRD §5): a `ReturnInst`, a
// measurement, or any terminator that does not fall straight through to
// `MergeBB`. On escape, diagnose at the offending instruction and return true.
// Collects the in-shadow gate-body ops into `Shadow` as it goes.
bool armEscapesOrCollect(BasicBlock *Arm, BasicBlock *MergeBB,
                         SmallVectorImpl<Instruction *> &Shadow) {
  for (Instruction &I : *Arm) {
    if (isa<ReturnInst>(&I)) {
      diagnoseEscape(&I, "return");
      return true;
    }
    if (isMeasureCall(I)) {
      diagnoseEscape(&I, "measurement");
      return true;
    }
    if (auto *Br = dyn_cast<BranchInst>(&I)) {
      // The arm's terminator must be an unconditional fall-through to the
      // merge. A conditional branch or a branch elsewhere leaves the region.
      if (Br->isConditional() || Br->getSuccessor(0) != MergeBB) {
        diagnoseEscape(&I, "control-flow escape");
        return true;
      }
      continue;  // the well-formed fall-through; not a shadow op.
    }
    if (isPhiCall(I))
      Shadow.push_back(&I);
  }
  return false;
}

// Recognize a 2-block diamond: a `br i1 %cond, A, B` where exactly one
// successor is a single-predecessor "arm" that unconditionally branches to the
// other successor (the "merge"). Sets `Arm`/`MergeBB` and returns true on a
// match. The merge must have a `PHINode` (the `[modified, original]` φ) — a
// no-φ diamond is not WP3's shape.
bool matchDiamond(BranchInst *Br, BasicBlock *&Arm, BasicBlock *&MergeBB) {
  BasicBlock *S0 = Br->getSuccessor(0);
  BasicBlock *S1 = Br->getSuccessor(1);

  // Try each successor as the arm; the other is the candidate merge.
  for (int i = 0; i < 2; ++i) {
    BasicBlock *CandArm = i == 0 ? S0 : S1;
    BasicBlock *CandMerge = i == 0 ? S1 : S0;
    // The arm is guarded by exactly this branch (single predecessor) and
    // unconditionally continues to the merge.
    if (CandArm->getSinglePredecessor() != Br->getParent())
      continue;
    auto *ArmTerm = dyn_cast<BranchInst>(CandArm->getTerminator());
    if (!ArmTerm || ArmTerm->isConditional())
      continue;
    if (ArmTerm->getSuccessor(0) != CandMerge)
      continue;
    // The merge must carry the SSA merge `φ` this region dissolves.
    if (!isa<PHINode>(&CandMerge->front()))
      continue;
    Arm = CandArm;
    MergeBB = CandMerge;
    return true;
  }
  return false;
}

}  // namespace

ControlPlan detectControlRegions(Module &M, TaintSet &taint) {
  ControlPlan plan;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      // WP4: a tainted-condition `select i1` whose arms are BOTH classical is
      // the single-block `if/else`-over-constants reduction (PRD §2.2). It has
      // no CFG diamond — `Pred`/`Arm`/`MergeBB` stay null, so linearization is
      // a no-op for it. The "both arms classical" test is the exact
      // discriminator: it excludes WP5's `&&`/`||` flag-selects (an arm is a
      // tainted i1 flag) and the deferred `[≥1 tainted arm]` data mux (§5.5).
      for (Instruction &I : BB) {
        auto *Sel = dyn_cast<SelectInst>(&I);
        if (!Sel)
          continue;
        // §1.3: keyed strictly on taint of the condition (same test as `br`).
        // A classical-condition select is left byte-untouched (§1.3, WP6).
        if (!taint.Tainted.count(Sel->getCondition()))
          continue;
        // Both value arms must be classical (neither tainted). This is the
        // load-bearing discriminator (see above); do NOT special-case the i1
        // result type — the arm-taint test already excludes flag-selects.
        if (taint.Tainted.count(Sel->getTrueValue()) ||
            taint.Tainted.count(Sel->getFalseValue()))
          continue;

        ControlRegion region;
        region.Condition = Sel->getCondition();
        region.Kind = ControlRegion::SelectRegion;
        region.Merge = Sel;  // dissolved by MergeDissolution; no CFG.
        region.Depth = 0;
        // No Pred/Arm/MergeBB and no Shadow — a classical-arm select has no
        // in-shadow gate body and no diamond.
        plan.Regions.push_back(std::move(region));
      }

      auto *Br = dyn_cast<BranchInst>(BB.getTerminator());
      if (!Br || !Br->isConditional())
        continue;
      // §1.3: a controlled region is exactly a TAINTED-condition branch. A
      // classical condition is left byte-untouched (no region built).
      if (!taint.Tainted.count(Br->getCondition()))
        continue;

      BasicBlock *Arm = nullptr;
      BasicBlock *MergeBB = nullptr;
      if (!matchDiamond(Br, Arm, MergeBB))
        continue;  // not the WP3 2-block-diamond shape.

      // Escape guard + shadow collection in one arm walk (PRD §5).
      ControlRegion region;
      if (armEscapesOrCollect(Arm, MergeBB, region.Shadow))
        continue;  // diagnosed; region skipped.

      region.Condition = Br->getCondition();
      region.Kind = ControlRegion::BranchRegion;
      region.Merge = &MergeBB->front();  // the merge PHINode.
      region.Pred = &BB;
      region.Arm = Arm;
      region.MergeBB = MergeBB;
      region.Depth = 0;

      for (Instruction *S : region.Shadow)
        plan.InShadow.insert(S);
      plan.Regions.push_back(std::move(region));
    }
  }

  return plan;
}

}  // namespace cq
