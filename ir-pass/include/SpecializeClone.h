// SpecializeClone.h — clone mechanics for Phase 6 call-graph specialization.
//
// Lifts the archived `cloneAndMangle` (`CloneFunction` + `ValueToValueMapTy` +
// `setLinkage(InternalLinkage)`) with two net-new changes (DD-5): the mangle is
// `__cq_q_<callee>_<mask>` (replacing the prototype's `_q1`) and the dedup key
// is `(callee, mask)` (replacing the prototype's signature-collapsing
// `Function*`-only key, C7). No taint, no lowering, no Bennett wrap — those are
// `SpecializeSeed` / the scoped lowering substages / `BennettWrap`.

#ifndef CQ_IRPASS_SPECIALIZE_CLONE_H_
#define CQ_IRPASS_SPECIALIZE_CLONE_H_

#include "SpecializePlan.h"

namespace cq {

// Clone `Cand.Callee`, mangle `__cq_q_<callee>_<mask>`, set internal linkage,
// and return the clone. The caller (`Specialization`) is responsible for the
// `(callee, mask)` cache: a cache hit must NOT re-clone (this always mints a
// fresh clone). The clone is inserted into `Cand.Callee`'s module.
llvm::Function *cloneFor(const SpecCandidate &Cand);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_CLONE_H_
