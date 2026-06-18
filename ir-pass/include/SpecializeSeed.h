// SpecializeSeed.h — the net-new param-root taint seed (C15).
//
// `propagate` seeds taint ONLY at `@cq_theta` results and has no path to seed a
// Function `Argument`. A clone's quantum inputs arrive as already-i32-handle
// PARAMETERS, so Phase 6 needs a param-root seed. `seedClone` builds a FRESH
// `cloneTaint` — its `Value*` are NEVER unioned into the original module `taint`
// (C-Taint: the disjoint-TaintSet boundary is what prevents the clone-body
// double-uncompute, DD-2) — by inserting each masked `clone->getArg(i)` and
// running the forward worklist SCOPED to the clone body. The original module is
// never re-walked.

#ifndef CQ_IRPASS_SPECIALIZE_SEED_H_
#define CQ_IRPASS_SPECIALIZE_SEED_H_

#include "SpecializePlan.h"
#include "TaintPropagation.h"

namespace llvm {
class Function;
}  // namespace llvm

namespace cq {

// Seed taint on each `Clone` parameter whose `Mask` bit is set and forward-
// propagate within `Clone` only. Returns the fresh, clone-scoped `cloneTaint`.
TaintSet seedClone(llvm::Function *Clone, SpecMask Mask);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_SEED_H_
