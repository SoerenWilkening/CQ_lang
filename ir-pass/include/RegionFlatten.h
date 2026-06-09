// RegionFlatten.h — CFG flatten for one swap-route control region (swap-route
// 4.1 IMPLEMENTATION §1/§4 step 9). After `SwapRouteEmit` has emitted the routed
// stream into the pred block and rewired the data (RAUW merge phi → routed
// handle, erased the merge phi + arm `cq_phi`), the region's diamond/if-else CFG
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

namespace cq {

struct ControlRegion;
struct TaintSet;

// Flatten one region's diamond/if-else CFG into its pred block. Reads the
// region's `Pred`/`Arm`/`ArmFalse`/`MergeBB`/`Condition` anchors (set by
// `ControlDetect::recoverRegion`). `taint` is mutated: the dead condition
// compare is scrubbed when erased. Assumes `SwapRouteEmit` has already emitted
// the stream and rewired/erased the phi + arm gate bodies.
void flattenRegion(const ControlRegion &R, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_REGION_FLATTEN_H_
