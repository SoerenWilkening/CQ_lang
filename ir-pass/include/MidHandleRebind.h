// MidHandleRebind.h — Mid-struct → i32-handle SSA rebinding. Was
// inline in `CQLoweringPass.cpp` steps 2–3 (pre-Phase-2-M12).
//
// For every init in `taint.InitCalls`, emit `cqrt_alloc_<W>(value)`
// adjacent to it and rewire mid-struct traffic to i32 handles. Both
// `-O0` struct shape (extractvalue rewired) and `-O1` SROA-flattened
// shape (init RAUW'd) are recognized. Mutates `taint`: each emitted
// alloc is inserted into `taint.Tainted`; each erased extractvalue is
// removed (avoids a dangling-pointer hit when a later allocator slot
// reuses the same address). `BirthOrder` is seeded with alloc
// creation order; `OpcodeLowering` extends it for template results
// and consumes it for stable Q+Q operand canonicalization.

#ifndef CQ_IRPASS_MID_HANDLE_REBIND_H_
#define CQ_IRPASS_MID_HANDLE_REBIND_H_

#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Value.h"

namespace cq {

class WidthDispatch;
struct TaintSet;

struct RebindMap {
  // Init-call → alloc-handle map. `MeasureLowering` reads this via
  // operand pattern (a): a measure whose argument is a known init call
  // resolves the handle directly.
  llvm::DenseMap<llvm::Value *, llvm::Value *> StructToHandle;

  // SSA-value birth order for stable Q+Q operand canonicalization. The
  // initial entries are the allocs emitted here (one per init, in
  // collection order); `OpcodeLowering` adds template-result handles.
  // 0 means "not assigned"; only canonicalized values have non-zero
  // entries.
  llvm::DenseMap<llvm::Value *, unsigned> BirthOrder;
  unsigned NextBirth = 1;
};

// Emits allocs, RAUWs/rewires mid-struct traffic to i32 handles, and
// updates `taint` to reflect the rewriting (allocs in, dead extractvalues
// out). Returns the rebind map for downstream consumers.
RebindMap rebindMids(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_MID_HANDLE_REBIND_H_
