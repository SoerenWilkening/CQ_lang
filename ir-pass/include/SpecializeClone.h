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
class CallInst;
class Function;
}  // namespace llvm

namespace cq {

struct TaintSet;

// The RETURN-TAINT PREDICTOR (bd 3c6m.54, 5po2 I2): does `Callee`'s return value,
// with the parameters in `Mask` quantum, carry taint? A pure forward transitive-user
// closure from the masked parameters — the closure `seedClone` builds on the clone —
// plus "any conditional terminator in that closure ⇒ tainted". A sound
// OVER-approximation of the `ReturnTainted` verdict `buildClone` later computes: every
// clone stage after `seedClone` either removes taint (the inner classical-clone scrub,
// the dead-slot deletion) or replaces a value already in the closure (the PredMux
// flatten's selects replace φs / branches the closure reaches; main's control
// chain, `lowerQramReads` and `lowerOps` RAUW members of the closure). So `false` means the
// clone's return is classical. Two consumers, and the first is no longer the only one:
//   * `cloneFor` — the fp-return signature (i32 handle vs the fp value);
//   * `specCallResultPredictedClassical` below — the propagation-time classical verdict
//     for a would-be Phase-6 site's RESULT (bd cepm / bd 3zr4).
// Defined in SpecializeClone.cpp.
bool predictReturnTainted(llvm::Function *Callee, SpecMask Mask);

// bd `test_C_libtooling-cepm` / bd `test_C_libtooling-3zr4` — THE PROPAGATION-TIME
// CLASSICAL VERDICT for a call that will be a Phase-6 site. True iff `CI` is a direct
// call to an exact, non-variadic, non-reserved-name DEFINITION of arity ≤
// `kSpecMaxArity`, called with the callee's own function type, with a non-void result,
// not a front-end intrinsic site, with ≥1 argument in `taint.Tainted`, and
// `predictReturnTainted(callee, <that mask>)` is FALSE. Asked by `propagateWorklist`
// (every drain: `propagate`, the round-2 reseed and its onward fixpoint,
// `propagateFromSeeds`) at the moment it would taint `CI` as a user of a tainted
// argument: a true answer leaves the RESULT classical, so no stage between propagation
// and `specialize()` ever reads it as a register (the hand-inlined twin's view). WITHIN
// one drain a revisit with a grown mask re-asks (the predictor is monotone in `Mask`).
// ⚠ ACROSS drains it does not (round 1b, TaintPropagation.cpp; "a later drain … re-asks
// with the grown mask" stood here and let a ROUND-2 mask-growth site be tainted in
// round 2, accepting programs the oracle declines, TRACK_CEPM_3ZR4.md §5.2.1): the
// drain's SETTLE step taints, in the drain that recorded it, every site whose POSSIBLE
// final mask (plus the arguments a later round can taint — `LaterTaintOracle`) predicts
// a quantum return — the pre-cepm behaviour for such a site — and a site a drain of an
// EARLIER generation left classical is STICKY: a later drain never taints it.
// Why it is safe, and what backstops it:
//   * every call this answers true for is a Phase-6 site or a loud decline — it reads a
//     tainted argument and calls a definition, so `detectSpecializations` (round 1, or
//     round 2 on its reseed set) puts it in `Pending` or diagnoses it; one in neither
//     is refused by `declineTaintEscapes`' `kMsgUnknownCallee`;
//   * for a `Pending` site, `specialize()` CHECKS the prediction: a site whose result
//     was NOT tainted when it resolves but whose clone returns a register is a LOUD
//     decline (`kMsgPredictedClassicalQuantum`), never the old silent re-mark. It is
//     what the STICKY rule falls back on when the settle step under-approximates a
//     later round's growth.
// Defined in SpecializeClone.cpp.
bool specCallResultPredictedClassical(const llvm::CallInst &CI,
                                      const TaintSet &taint);

// Clone `Cand.Callee`, mangle `__cq_q_<callee>_<mask>`, set internal linkage,
// strip the stale pure-classical attributes (see `stripStaleClassicalAttrs`),
// and return the clone. The caller (`Specialization`) is responsible for the
// `(callee, mask)` cache: a cache hit must NOT re-clone (this always mints a
// fresh clone). The clone is inserted into `Cand.Callee`'s module.
llvm::Function *cloneFor(const SpecCandidate &Cand);

// bd p3kd.7.8: install the clone's fp-ABI signature (a tainted fp param or a
// predicted-tainted fp return becomes an i32 handle) AFTER main's stage list ran
// on the clone. Replaces `Clone` in place (same module position, name, attrs,
// metadata; the body is spliced, so body values keep their identity) and returns
// the new function, or `Clone` itself when no slot changes. The caller re-keys
// every record held on the old function or its arguments.
llvm::Function *retypeCloneSignature(llvm::Function *Clone,
                                     const SpecCandidate &Cand);

// Strip the function/return attributes a pure-classical body carried but the
// quantum-lowered body invalidates (`memory(none)`/`willreturn`/`nofree`, the
// return `range`). MUST be applied to every quantum-lowered clone AND its
// uncompute twin: a stale `memory(none) willreturn` lets the backend delete a
// void clone call whose result is unused (the Phase-6.3 twin), freeing the
// entangled rail DIRTY — a hidden measurement (Rule 6/8). It also demotes every
// `musttail` call in the body to no tail kind (the Bennett wrap emits code after an
// inner clone call, so a kept `musttail` aborts the verifier, exit 134 — bd m5pn;
// a `preallocated` forward is declined earlier by `scanBody`; see the definition).
void stripStaleClassicalAttrs(llvm::Function *F);

}  // namespace cq

#endif  // CQ_IRPASS_SPECIALIZE_CLONE_H_
