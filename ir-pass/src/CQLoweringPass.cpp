// CQLoweringPass.cpp — thin orchestrator for the cq-lowering pass.
//
// Per-step bodies live in width-resolver / taint / rotation / opcode /
// measure modules. Width parameterization handles `_Bool` / `i8` /
// `i16` / `i64` / `f32` / `f64`.

#include "CQLoweringPass.h"

#include "ControlPlan.h"
#include "ControlledLowering.h"
#include "MeasureLowering.h"
#include "OpcodeLowering.h"
#include "RotationLowering.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Module-level cleanup: erase the front-end intrinsic declarations now
// that all call sites have been lowered. Matches the architecture's
// promise that no @cq_theta_<sfx> / @cq_phi_<sfx> / @cq_measure_<sfx>
// remains in the IR after this pass. Gated on Changed so a passthrough-
// classical module stays byte-identical.
void eraseDeadDecls(Module &M, WidthDispatch &wd) {
  for (StringRef Name : wd.frontEndIntrinsicNames()) {
    if (Function *FE = M.getFunction(Name)) {
      if (FE->use_empty())
        FE->eraseFromParent();
    }
  }
}

}  // namespace

PreservedAnalyses CQLoweringPass::run(Module &M, ModuleAnalysisManager &) {
  WidthDispatch wd(M);
  TaintSet taint = propagate(M, wd);

  // No quantum work anywhere in the module: leave the IR byte-identical
  // and (crucially) emit no runtime/template decls. The
  // passthrough_no_quantum LIT fixture pins this path. PhiCalls is in the
  // predicate so a classical-only-phi module still runs (and deletes the
  // phi) — else an unresolved @cq_phi_* extern is a Stage-3 link error.
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty() &&
      taint.MeasureCalls.empty())
    return PreservedAnalyses::all();

  // Detect controlled regions (PURE ANALYSIS) right after propagation, so the
  // plan's in-shadow set is available to `lowerRotations` (which must skip the
  // gate-body `cq_phi` calls the controlled orchestrator lowers instead, §1.4).
  ControlPlan plan = detectControlRegions(M, taint);

  // The lowered calls are erased inside each step, so nothing dangles and
  // there is no separate dead-init sweep.
  lowerRotations(M, wd, taint, &plan);
  lowerControlledRegions(M, wd, taint, plan);
  lowerOps(M, wd, taint);
  lowerMeasures(M, wd, taint);
  eraseDeadDecls(M, wd);

  return PreservedAnalyses::none();
}

bool CQLoweringPass::runOnFunction(Function &F) {
  // Compatibility shim for any unit-level caller of the per-function
  // entry point. The canonical lowering loop runs at module scope
  // (so the WidthDispatch / TaintSet objects can amortize across
  // functions); this wrapper preserves the historical Function&
  // signature by routing through a single-function "module view."
  Module &M = *F.getParent();
  WidthDispatch wd(M);
  TaintSet taint = propagate(M, wd);
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty() &&
      taint.MeasureCalls.empty())
    return false;

  // Restrict the work lists to the requested function. Callers of
  // runOnFunction expect side-effects only on F.
  auto onlyInF = [&F](auto &Calls) {
    Calls.erase(std::remove_if(Calls.begin(), Calls.end(),
                               [&F](CallInst *CI) {
                                 return CI->getFunction() != &F;
                               }),
                Calls.end());
  };
  onlyInF(taint.ThetaCalls);
  onlyInF(taint.PhiCalls);
  onlyInF(taint.MeasureCalls);
  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty() &&
      taint.MeasureCalls.empty())
    return false;

  ControlPlan plan = detectControlRegions(M, taint);
  lowerRotations(M, wd, taint, &plan);
  lowerControlledRegions(M, wd, taint, plan);
  lowerOps(M, wd, taint);
  lowerMeasures(M, wd, taint);
  eraseDeadDecls(M, wd);
  return true;
}

}  // namespace cq
