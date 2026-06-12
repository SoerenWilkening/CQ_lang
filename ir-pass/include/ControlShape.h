// ControlShape.h — Tainted-control region SHAPE recovery (pure analysis).
//
// Declares the by-SSA-identity shape recognizers `ControlDetect.cpp` uses to
// turn a tainted-condition `br i1` into a normalized `ControlRegion` BEFORE any
// IR mutation (Rule 9). De-anonymized from `ControlDetect.cpp`'s anonymous
// namespace (WI-0/MD1) so the 4.3 `RegionTreeDetect` TU — which recursively
// recovers the depth-2 nest by reusing `recoverRegion`/`soleMergePhi`/
// `hasTaintedCondBranch` — can link against them instead of re-implementing the
// recognizers. PURE REFACTOR: the definitions still live in `ControlDetect.cpp`,
// only their linkage changed (anonymous → named `cq`).
//
// Everything here is recognition by SSA-value identity; no IR is mutated. See
// swap-route 4.1 IMPLEMENTATION §0/§3 and 4.3 IMPLEMENTATION-4.3 §1/§3.

#ifndef CQ_IRPASS_CONTROL_SHAPE_H_
#define CQ_IRPASS_CONTROL_SHAPE_H_

namespace llvm {
class BasicBlock;
class BranchInst;
class PHINode;
}  // namespace llvm

namespace cq {

struct ControlRegion;
struct TaintSet;

// The recognized shape of a tainted-condition `br` region.
enum class RegionShape { Diamond, IfElse, Nested, OffPattern };

// `BB`'s unique successor iff it ends in an UNCONDITIONAL branch; else null.
llvm::BasicBlock *uncondSucc(llvm::BasicBlock *BB);

// Does `BB` end in a tainted-condition conditional branch? (the nested-control
// signal — an arm that is itself a quantum-controlled region.)
bool hasTaintedCondBranch(llvm::BasicBlock *BB, TaintSet &Taint);

// The sole 2-incoming merge `φ` of block `M`. Null if `M` has not exactly one
// PHINode, or that phi is not 2-incoming (a mixed gate+angle merge, or a
// shared/nested merge with >2 predecessors → decline generic, never mis-lower).
// The relaxed 3-incoming recognizer for nests lives in `RegionTreeDetect`
// (never relax this 2-incoming gate for FLAT regions).
llvm::PHINode *soleMergePhi(llvm::BasicBlock *M);

// Recognize the §0 diamond / if-else shape of a tainted-condition `br` by SSA
// identity, populating `R` (Condition/Pred/Arm/ArmFalse/MergeBB/Merge and the
// Rule-9 ArmNegated polarity). Returns the shape, or OffPattern/Nested to
// decline. Never assumes successor 0 is the taken arm.
RegionShape recoverRegion(llvm::BranchInst *BI, TaintSet &Taint,
                          ControlRegion &R);

}  // namespace cq

#endif  // CQ_IRPASS_CONTROL_SHAPE_H_
