// CQLoweringPass.cpp — thin orchestrator for the cq-lowering pass.
//
// Per-step bodies live in width-resolver / taint / rebind / opcode /
// measure modules. Width parameterization handles `_Bool` / `i8` /
// `i16` / `i64` / `f32` / `f64`.

#include "CQLoweringPass.h"

#include "MeasureLowering.h"
#include "MidHandleRebind.h"
#include "OpcodeLowering.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

namespace {

// Step 7 (legacy): erase init calls that became use-less after rebind
// (flattened-shape RAUW) and measure lowering (struct-shape, extractvalue
// + insertvalue traffic gone). Inits with surviving uses stay in place —
// that's the diagnostic-surface preference: a dangling cq_init survives
// to a later verifier run instead of being silently dropped.
void eraseDeadInits(TaintSet &taint) {
  for (CallInst *Init : taint.InitCalls) {
    if (Init->use_empty())
      Init->eraseFromParent();
  }
}

// Module-level cleanup: erase the front-end intrinsic declarations now
// that all call sites have been lowered. Matches the architecture's
// promise that no @cq_init_<sfx> / @cq_measure_<sfx> remains in the IR
// after this pass. Gated on Changed so a passthrough-classical module
// stays byte-identical.
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
  // passthrough_no_quantum LIT fixture pins this path.
  if (taint.InitCalls.empty() && taint.MeasureCalls.empty())
    return PreservedAnalyses::all();

  RebindMap rebind = rebindMids(M, wd, taint);
  lowerOps(M, wd, taint, rebind);
  lowerMeasures(M, wd, taint, rebind);
  eraseDeadInits(taint);
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
  if (taint.InitCalls.empty() && taint.MeasureCalls.empty())
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
  onlyInF(taint.InitCalls);
  onlyInF(taint.MeasureCalls);
  if (taint.InitCalls.empty() && taint.MeasureCalls.empty())
    return false;

  RebindMap rebind = rebindMids(M, wd, taint);
  lowerOps(M, wd, taint, rebind);
  lowerMeasures(M, wd, taint, rebind);
  eraseDeadInits(taint);
  eraseDeadDecls(M, wd);
  return true;
}

}  // namespace cq
