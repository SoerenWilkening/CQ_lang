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

namespace llvm {
class Function;
}  // namespace llvm

namespace cq {

// Clone `Cand.Callee`, mangle `__cq_q_<callee>_<mask>`, set internal linkage,
// strip the stale pure-classical attributes (see `stripStaleClassicalAttrs`),
// and return the clone. The caller (`Specialization`) is responsible for the
// `(callee, mask)` cache: a cache hit must NOT re-clone (this always mints a
// fresh clone). The clone is inserted into `Cand.Callee`'s module.
llvm::Function *cloneFor(const SpecCandidate &Cand);

// Strip the function/return attributes a pure-classical body carried but the
// quantum-lowered body invalidates (`memory(none)`/`willreturn`/`nofree`, the
// return `range`). MUST be applied to every quantum-lowered clone AND its
// uncompute twin: a stale `memory(none) willreturn` lets the backend delete a
// void clone call whose result is unused (the Phase-6.3 twin), freeing the
// entangled rail DIRTY — a hidden measurement (Rule 6/8). It also demotes every
// `musttail` call in the body to no tail kind (the Bennett wrap emits code after an
// inner clone call, and the fp→i32 rewrite changes prototypes — a kept `musttail`
// aborts the verifier, exit 134; see the definition).
void stripStaleClassicalAttrs(llvm::Function *F);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_CLONE_H_
