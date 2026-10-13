// HoistRoute.cpp — the 6.5 hoist's route and argument predicates over the
// PoisonFlow.cpp dataflow (moved out of PoisonFlow.cpp in batch 053, <= 400
// lines). `classicalCallHoistRoute`: PoisonFlow.h; `hoistedArgPoisonIsUB`,
// `hoistedCallTreeIsUBFree`: SpeculationSafety.h; `freezeDischargesHoistedArg`:
// ArmClassify.h. The claim and the emitter ask the same functions (bd 9hea, bwfp,
// dm7f.21).
#include "PoisonFlow.h"

#include "ArmClassify.h"        // freezeDischargesHoistedArg (declared there, bd 9hea)
#include "CallContract.h"
#include "PredMuxFlatten.h"     // isSpeculatableTotalCallee
#include "SpeculationSafety.h"  // callExecutionIsDefined, hoisted* (declared there)
#include "TwinTotality.h"       // TwinTotality

#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;
namespace cq {

bool hoistedArgPoisonIsUB(const CallBase *C, unsigned N) {
  if (C->paramHasAttr(N, Attribute::NoUndef))
    return true;
  const auto *CI = dyn_cast<CallInst>(C);
  return !CI || N >= 64 || hoistUBWithPoisonArgs(CI, uint64_t(1) << N);
}

// Same effective call-site/callee union as the original 9hea predicate.
// Total classical speculation additionally stabilizes parameters without
// noundef: their bodies may pass them onward to a constrained inner call.
bool freezeDischargesHoistedArg(const CallBase *C, unsigned N) {
  return hoistedArgPoisonIsUB(C, N) && argAttrsAreInert(C, N);
}

bool hoistedCallTreeIsUBFree(const CallInst *Call) {
  if (!callExecutionIsDefined(Call))
    return false;
  // A value-constraining attribute on the hoisted call's own parameter (`range`,
  // `nonnull`, ... with `noundef`) is UB for a DEFINED argument the source's
  // guard kept out of its domain (review round 2 F2), so only inert ones pass:
  // the same contract an inner call must meet (review round 3 F3).
  for (unsigned N = 0; N != Call->arg_size(); ++N)
    if (!paramContractIsInert(Call, N))
      return false;
  // Every argument whose poison would be UB is frozen (`hoistedArgPoisonIsUB`);
  // the rest may stay poison without UB by construction, so the body must be
  // UB-free with all arguments defined.
  return !hoistUBWithPoisonArgs(Call, 0);
}

// Batch 053: the route owns the whole totality question (the 6.5 claim keeps
// only memory(none) + nounwind). DIRECT runs the original on every basis state,
// so it needs `willreturn` and the claim's two totality proofs (`speculatable`,
// or the strict body walk) on top of UB-freedom. TWIN runs a twin that is total
// by construction and terminates within ScalarEvolution's constant max trip
// count (TwinTotality.h; owner-ruling-twin-divergence-bounded-2026-10-13): it
// stands in for both.
HoistRoute classicalCallHoistRoute(const CallInst *Call) {
  const Function *F = Call->getCalledFunction();
  if (!F || !callExecutionIsDefined(Call))
    return HoistRoute::Unsafe;
  if (Call->willReturn() &&
      (isSafeToSpeculativelyExecute(Call) || isSpeculatableTotalCallee(F)) &&
      hoistedCallTreeIsUBFree(Call))
    return HoistRoute::Direct;
  // The root site's own parameter contract: the twin and the redirected site
  // drop `range`/`nofpclass`/`returned` (dm7f.25); nothing else is shed.
  for (unsigned N = 0; N != Call->arg_size(); ++N)
    if (!twinParamContractHolds(Call, N))
      return HoistRoute::Unsafe;
  // The twin's result is defined, but a poison-generating flag on the call site
  // itself (fast-math) could still poison a `noundef` result. Only a body the
  // TOTALITY walk admits is twinned (R11 round 1, H2): a `speculatable` BODY
  // promises nothing about the arbitrary values a freeze yields, so every body in
  // the twin's tree is walked (memory-free, guarded divisors, bounded loops).
  if (F->isIntrinsic() ||
      ((Call->hasPoisonGeneratingFlags() || Call->hasPoisonGeneratingMetadata()) &&
       Call->hasRetAttr(Attribute::NoUndef)))
    return HoistRoute::Unsafe;
  TwinTotality Tot;
  if (!Tot.admits(*F) || twinFlowIsHard(*F))
    return HoistRoute::Unsafe;
  return HoistRoute::Twin;
}

}  // namespace cq
