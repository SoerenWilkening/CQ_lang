// SpeculationTwin.h — bd dm7f.21: build the speculation-safe twin the 6.5 hoist
// calls in place of a callee whose own `noundef` sinks may see poison on a basis
// state the source's guard excluded (owner ruling 2026-10-08). The edits are
// `TwinPlanner::edits` (PoisonFlow.h), read off the original body and then
// re-read off the built twin itself until it plans nothing; this file applies them.
//
// The twin is a new internal function `__cq_specsafe_<callee>` cached per callee
// so every caller and every transitive callee shares one. The original body is
// untouched for its other callers. It is purely classical: it keeps the callee's
// purity attributes, mints no `cqrt_*`, and stage 3 compiles it verbatim.
//
// bd r2j3.22: a twin is found again ONLY through this pass's own registry of the
// twins it built and verified (keyed by the original, cross-checked against the
// `!cq.specsafe.twin` attachment, which is kept for readers). The attachment
// alone is never trusted: a module may carry a user-written function with that
// name and tag and any body (the 9oob family).
//
// Batch 053 (TwinTotality.h) widens the body: the twin of a branching callee
// freezes its conditions (dm7f.29), guards a possibly-zero divisor (dm7f.30),
// bounds each counted loop by a ScalarEvolution trip counter (dm7f.27), drops
// value-constraining parameter attributes (dm7f.25), and the twin of a bodyless
// `speculatable` callee is a wrapper `ret freeze(call F(...))` (dm7f.26).
#ifndef CQ_SPECULATION_TWIN_H
#define CQ_SPECULATION_TWIN_H

namespace llvm {
class CallInst;
class Function;
}  // namespace llvm

namespace cq {

// `F`'s twin, built and verified (with every inner twin it calls) on first use.
// nullptr, with every unverified twin it built erased, when `TwinPlanner::edits`
// refuses a body, the totality walk refuses it, or an edit site would be edited
// twice; the emitter then declines loudly. None is reached for a callee the
// claim routed to a twin (`classicalCallHoistRoute` asked the same walks).
llvm::Function *getOrCreateSpeculationTwin(llvm::Function &F);

// Is `T` a twin this pass built and verified (registry, never the tag alone)?
bool isVerifiedTwin(const llvm::Function &T);

// Point `Call` at `Twin`. The twin's result is defined but no longer carries a
// value constraint, so the call site keeps only `noundef`/`zeroext`/`signext`/
// `inreg` on its return and drops every parameter attribute the twin dropped
// (`twinDroppedParamAttrs`, CallContract.h).
void callSpeculationTwin(llvm::CallInst &Call, llvm::Function &Twin);

}  // namespace cq

#endif  // CQ_SPECULATION_TWIN_H
