// SpeculationTwin.h — bd dm7f.21: build the speculation-safe twin the 6.5 hoist
// calls in place of a callee whose own `noundef` sinks may see poison on a basis
// state the source's guard excluded (owner ruling 2026-10-08). The edits are
// `TwinPlanner::edits` (PoisonFlow.h), read off the original body and then
// re-read off the built twin itself until it plans nothing; this file applies them.
//
// The twin is a new internal function `__cq_specsafe_<callee>` cached per callee
// (found again through its `!cq.specsafe.twin` attachment naming the original,
// set only once the twin is verified),
// so every caller and every transitive callee shares one. The original body is
// untouched for its other callers. It is purely classical: it keeps the callee's
// purity attributes, mints no `cqrt_*`, and stage 3 compiles it verbatim.
#ifndef CQ_SPECULATION_TWIN_H
#define CQ_SPECULATION_TWIN_H

namespace llvm {
class CallInst;
class Function;
}  // namespace llvm

namespace cq {

// `F`'s twin, built and verified (with every inner twin it calls) on first use.
// nullptr, with every unverified twin it built erased, when `TwinPlanner::edits`
// refuses a body or an edit site would be edited twice; the emitter then declines
// loudly. Neither is reached for a callee the claim routed to a twin: the strict
// walk leaves only freezable sinks, and each site is edited at most once.
llvm::Function *getOrCreateSpeculationTwin(llvm::Function &F);

// Point `Call` at `Twin`. The twin's result is defined but no longer carries a
// value constraint, so the call site keeps only `noundef`/`zeroext`/`signext`/
// `inreg` on its return and drops any `returned` parameter attribute.
void callSpeculationTwin(llvm::CallInst &Call, llvm::Function &Twin);

}  // namespace cq

#endif  // CQ_SPECULATION_TWIN_H
