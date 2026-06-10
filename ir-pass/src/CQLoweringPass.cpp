// CQLoweringPass.cpp — thin orchestrator for the cq-lowering pass.
//
// Per-step bodies live in width-resolver / taint / rotation / opcode /
// measure modules. Width parameterization handles `_Bool` / `i8` /
// `i16` / `i64` / `f32` / `f64`.

#include "CQLoweringPass.h"

#include "ControlPlan.h"
#include "MeasureLowering.h"
#include "OpcodeLowering.h"
#include "RotationLowering.h"
#include "SwapRouteEmit.h"
#include "TaintPropagation.h"
#include "Uncomputation.h"
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

  // Taint-escape guard (test_C_libtooling-bxv): pure analysis, FIRST — before
  // any mutation — because the escape is only diagnosable on pre-RAUW SSA
  // identity (after rotation lowering every tainted value IS the i32 handle
  // and an unknown call reading it is verify-clean). Declines loudly any
  // consumer of a tainted value the lowering does not own (unknown callee /
  // store / unsupported instruction).
  declineTaintEscapes(M, taint);

  // Straight-line stale-record guard (test_C_libtooling-uzb): pure analysis,
  // FIRST — before any mutation — because it needs SSA-record identity
  // (rotation lowering's RAUW collapses the pre-/post-Ry values onto one i32
  // handle) and the original schedule (= the emitted opaque-call stream). It
  // diagnoses loudly and marks `taint.StaleDeclined` for `lowerOps` to skip.
  declineStaleRecordOps(M, taint);

  // Tainted control flow: `detectControlRegions` (ControlDetect.cpp) recognizes
  // the swap-route phase-arm diamond/if-else shape by SSA identity (Rule 9, no
  // mutation), pushes each accepted phase-arm DIAMOND onto `plan.Regions`, and
  // declines everything else loudly ("… under quantum control", opt exits
  // non-zero). `lowerControlRegions` (SwapRouteEmit) then emits the coherent
  // routed stream per region — flag mint → |0> rail → cswap route-in → verbatim
  // Rz on rail → cswap route-back → rail free → icmp_inv flag-strip → flag free —
  // and flattens the CFG. It runs BEFORE `lowerRotations` so it can reference the
  // still-present `@cq_theta` result; the later RAUW-to-handle updates every
  // emitted call (Rule 9). A classical-condition branch stays byte-untouched.
  ControlPlan plan = detectControlRegions(M, taint);
  lowerControlRegions(M, wd, taint, plan);

  // The lowered calls are erased inside each step, so nothing dangles and
  // there is no separate dead-init sweep.
  lowerRotations(M, wd, taint, &plan);
  lowerOps(M, wd, taint);
  lowerMeasures(M, wd, taint);
  // Phase 5 (PRD §2.8): per-op uncomputation runs LAST, after every other
  // mutation has settled `taint` into its final post-lowering state.
  uncompute(M, wd, taint);
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

  // Taint-escape + stale-record guards run FIRST here too (twin-pipeline
  // trap, IMPLEMENTATION §6.5) — see run(). Both are module-scoped like
  // `lowerOps`, which also walks all of `M` (only the rotation/measure work
  // lists above are F-restricted).
  declineTaintEscapes(M, taint);
  declineStaleRecordOps(M, taint);

  // See run() — `detectControlRegions` pushes accepted phase-arm diamonds and
  // declines the rest; `lowerControlRegions` emits the routed stream. BOTH must
  // run in this entry point too, between detection and `lowerRotations`, or
  // unit-level callers silently diverge from `run()` (the twin-pipeline trap,
  // IMPLEMENTATION §6.5).
  ControlPlan plan = detectControlRegions(M, taint);
  lowerControlRegions(M, wd, taint, plan);
  lowerRotations(M, wd, taint, &plan);
  lowerOps(M, wd, taint);
  lowerMeasures(M, wd, taint);
  // Phase 5 (PRD §2.8): uncomputation runs LAST in this entry point too — miss
  // one and unit-level callers diverge from `run()`.
  uncompute(M, wd, taint);
  eraseDeadDecls(M, wd);
  return true;
}

}  // namespace cq
