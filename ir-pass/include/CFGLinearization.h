// CFGLinearization.h — Collapse a `br`-sourced region's diamond to a single
// straight-line block (PRD §2.11, IMPLEMENTATION §5.7). After controlled
// substitution put the gate body on the in-place handle and `MergeDissolution`
// dissolved the merge `φ`, the diamond's branch and arm blocks are dead. Erase
// the `br i1`, splice the arm's (now controlled, unconditional) ops into the
// predecessor, fold the merge block in too, and erase the dead `icmp` last.
// A `br i32` is NEVER created (§1.1). Collection-before-mutation (§1.6); the
// `φ` MUST already be dissolved so no use dangles.

#ifndef CQ_IRPASS_CFG_LINEARIZATION_H_
#define CQ_IRPASS_CFG_LINEARIZATION_H_

namespace llvm {
class Instruction;
}  // namespace llvm

namespace cq {

struct ControlRegion;

// Linearize the diamond of a `BranchRegion` into `region.Pred`. Returns the
// instruction at the merge-block boundary that downstream work (the flag
// uncompute, §1.5) should be inserted BEFORE — i.e. the first surviving
// instruction that came from the merge block (typically its `ret`). Returns
// nullptr if the region is not the expected `br` shape (left untouched).
llvm::Instruction *linearizeRegion(ControlRegion &region);

}  // namespace cq

#endif  // CQ_IRPASS_CFG_LINEARIZATION_H_
