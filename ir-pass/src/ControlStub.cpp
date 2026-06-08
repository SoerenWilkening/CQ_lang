// ControlStub.cpp — transitional stand-in for the removed controlled-form
// lowering.
//
// The old Phase-4 controlled-op control path (ControlDetection / ControlFlag /
// ControlledSubstitution / MergeDissolution / CFGLinearization /
// FlagConjunction / SwitchNormalization) was excised on the `swap-route-control`
// branch so the new RSSA swap-routing control lowering can be built WITHOUT the
// old controlled-op machinery shaping it (see ROADMAP "Phase 4 — RSSA
// swap-routed control flow" + docs/design/rssa-swap-control/).
//
// Until the swap-route emitter lands, tainted control flow has NO lowering. This
// stub preserves the one invariant that MUST hold in the interim: a tainted
// `br` / `select` / `switch` is NEVER silently passed through to the backend as
// classical control over quantum state — a verify-clean silent miscompile. It
// emits the loud `DiagnosticInfoUnsupported` ("… under quantum control") the
// removed `ControlDetection::diagnoseEscape` emitted, and returns an EMPTY plan,
// so `RotationLowering` lowers every rotation uncontrolled (its `InShadow`
// lookups are simply empty). A classical-condition branch/select/switch is left
// byte-untouched, exactly as before — detection keys strictly on condition taint.

#include "ControlPlan.h"
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

namespace {

// Same `DiagnosticInfoUnsupported(DS_Error)` surface + message form the removed
// `ControlDetection::diagnoseEscape` used, so the "… under quantum control"
// FileCheck idiom still holds and opt exits non-zero. The offending
// instruction's `!dbg` is attached so the rejection is source-located.
void diagnoseUnderControl(Instruction *Where, StringRef What) {
  std::string Msg =
      ("cq controlled lowering: " + What + " under quantum control").str();
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

}  // namespace

// Transitional detection: NO region recovery. Scan every function for a
// tainted-condition `br i1` / `select i1` / `switch` and diagnose it loudly;
// return an empty `ControlPlan`. The new swap-route emitter replaces this with
// real routing-based lowering.
ControlPlan detectControlRegions(Module &M, TaintSet &taint) {
  ControlPlan plan;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      Instruction *Term = BB.getTerminator();
      if (auto *BI = dyn_cast<BranchInst>(Term)) {
        if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
          diagnoseUnderControl(BI, "control flow");
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
