// TaintPropagation.h — Forward taint propagation from quantum init
// sources. Was inline in `CQLoweringPass.cpp` step 4 (pre-Phase-2-M12).
//
// M12 contract: walk the module, collect every `@cq_init_<sfx>` call
// site, seed the taint set with each init's RESULT SSA value, and
// forward-propagate through user instructions. Taint sinks
// (`@cq_measure_<sfx>`, `@cqrt_measure_<W>`) stop propagation —
// measurement is the canonical point where quantum state becomes
// classical. M14 widened the source set from `{cq_init_si32}` alone
// to every suffix in `WidthDispatch::allSuffixes()`; both init and
// measure intrinsic enumerations share that 14-suffix table.
//
// Propagation runs BEFORE `MidHandleRebind::rebindMids` (per PLAN.md
// §4.12 split contract). Consequence: the taint set initially contains
// pre-rebind SSA values — init struct returns, extractvalue %s, 0 i32s,
// downstream add results, etc. `rebindMids` updates the set as it
// rewrites mid-struct traffic: every newly-emitted `cqrt_alloc_<W>`
// handle is added, every erased extractvalue is removed.
//
// Spec: phases/phase2/PLAN.md §4.12, §4.14.

#ifndef CQ_IRPASS_TAINT_PROPAGATION_H_
#define CQ_IRPASS_TAINT_PROPAGATION_H_

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <set>

namespace cq {

class WidthDispatch;

struct TaintSet {
  // Front-end intrinsic call sites collected during the propagation
  // walk. `InitCalls` seeds the taint sources and feeds `MidHandleRebind`;
  // `MeasureCalls` is the work list for `MeasureLowering`. Collecting
  // both here avoids re-walking the module from those passes.
  llvm::SmallVector<llvm::CallInst *, 8> InitCalls;
  llvm::SmallVector<llvm::CallInst *, 8> MeasureCalls;

  // All SSA values that carry quantum taint at any point in the
  // pipeline. `MidHandleRebind` mutates this set (inserts allocs,
  // erases dead extractvalues); `OpcodeLowering` mutates it again as
  // tainted adds get rewritten to template-call results.
  std::set<llvm::Value *> Tainted;
};

// Walks every non-declaration function in `M`, collects init/measure
// intrinsic call sites in basic-block order, and runs the forward
// taint propagation. The work-list is seeded with each init's RESULT
// (struct in -O0 shape, i32 in -O1 SROA-flattened shape); both
// shapes feed the same propagation rules.
TaintSet propagate(llvm::Module &M, WidthDispatch &wd);

}  // namespace cq

#endif  // CQ_IRPASS_TAINT_PROPAGATION_H_
