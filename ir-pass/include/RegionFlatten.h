// RegionFlatten.h — CFG flatten for one tainted-condition control region
// (swap-route 4.1 IMPLEMENTATION §1/§4 step 9). After an emitter has put its
// stream into the pred block and rewired the data (RAUW'd + erased the merge phi,
// if any, and erased or hoisted the arm gates), the region's diamond/if-else CFG
// is dead control: the conditional `br`, the arm block(s), and the merge block
// exist only to host instructions that now all live in (or have moved to) the
// pred. This step linearizes them into the single pred block.
//
// It captures the block identities BEFORE the first erase (the block-lifetime
// hazard — a stale `BasicBlock*` dereferenced after `eraseFromParent` is a
// SIGSEGV on valid input), then: erases the conditional `br`; splices the merge
// block's surviving instructions (the measure / ret that consumed the now-RAUW'd
// phi) onto the end of the pred; erases the dead condition compare; and deletes
// the now-unreachable arm block(s) and the emptied merge block.
//
// 4.1 is single-region, so the pred is its own (trivial) post-dominator and no
// `computeFreePoint` generalization is needed here; 4.3 nesting reuses this
// recursively (then the cross-region block-lifetime case becomes live).

#ifndef CQ_IRPASS_REGION_FLATTEN_H_
#define CQ_IRPASS_REGION_FLATTEN_H_

#include "llvm/ADT/ArrayRef.h"

namespace llvm {
class CallInst;
}  // namespace llvm

namespace cq {

struct ControlRegion;
struct TaintSet;

// Flatten one region's diamond/if-else CFG into its pred block. Reads the
// region's `Pred`/`Arm`/`ArmFalse`/`MergeBB`/`Condition` anchors (set by
// `ControlDetect::recoverRegion`). `taint` is mutated: the dead condition
// compare is scrubbed when erased. Assumes `SwapRouteEmit` has already emitted
// the stream and rewired/erased the phi + arm gate bodies.
void flattenRegion(const ControlRegion &R, TaintSet &taint);

// Coordinated CFG flatten for a depth-2 nest (IMPLEMENTATION-4.3 §4/§12.4).
// `Outer.Arm` is the `Mid` block (= `Inner.Pred`); both levels share the SINGLE
// merge block `Outer.MergeBB` (== `Inner.MergeBB`). Unlike calling `flattenRegion`
// per region (which would erase the shared merge TWICE → SIGSEGV), this owns the
// FULL teardown in the one order that keeps every value use-empty when freed: the
// 3-incoming merge phi `Outer.Merge`, if any, RAUW'd → base and erased; both
// branches; both compares (BEFORE the arm gates — the §6.1 order); the `armPhis`
// gates in REVERSE order; then the shared merge spliced into `Pred` exactly once
// and the dead arm/merge blocks deleted. The merge phi and `armPhis` belonged to
// the pre-3qlq register-form nest: the one caller, `emitPhaseKickbackNestRegion`,
// passes a null phi and empty `armPhis`. `Pred` survives (it holds the stream).
void flattenRegionTree(const ControlRegion &Outer, const ControlRegion &Inner,
                       llvm::ArrayRef<llvm::CallInst *> armPhis, TaintSet &taint);

// N-way CFG flatten for an accepted tainted `switch` region (swap-route 4.5;
// IMPLEMENTATION-4.5 §4/§5). Reads `R.Pred` (the switch block — SURVIVES, holds
// the emitted stream), `R.SwitchArms[].Block` (the case-arm blocks — doomed,
// incl. empty passthrough arms), and `R.MergeBB` (doomed). Assumes the switch
// emitter (phase / value / data-mux) has already emitted the per-case stream and
// disposed of the merge phi (if any) and the arm gates.
// Captures every block identity BEFORE the first erase (the block-lifetime
// hazard), then: scrub+erase the `switch` terminator (a USER of the tainted
// scrutinee — §6.1); splice the merge's surviving instructions into `Pred`;
// delete the now-unreachable arm blocks, then the emptied merge block. Unlike
// `flattenRegion`, the scrutinee `q` is the LIVE quantum register (kept alive by
// the emitted eq-flags) and is NEVER erased — there is no dead i1 condition
// compare to drop.
void flattenSwitchRegion(const ControlRegion &R, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_REGION_FLATTEN_H_
