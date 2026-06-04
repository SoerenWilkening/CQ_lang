// FreePoint.h — SSA last-use point for a tainted terminal handle (Phase 5,
// PRD §2.4). Productionizes the prototype's `PostDominatorTree`-driven last-use
// computation (`archive/prototype/cq_pass.cpp:305-329`).
//
// Step 1 is the BASIC single-block form: collect the handle's instruction
// users, post-dominate to their nearest common block, and return the point
// just after the latest in-block user (else the block's first insertion point,
// after φ-nodes). A handle used by a `ret` escapes → no free point.
//
// Step 3 extends this in place with the full classification (PRD §2.5/§2.6/
// §2.9): `cqrt_measure_` sink exclusion → `Measured`; return / `main` /
// `cq_invert_*` escapes → `Escaped`; and loud `DiagnosticInfoUnsupported` for
// unrecognized escapes, post-measure uses, and loop-backedge-crossing ranges.
// The `Kind` enum and `(F, taint)` parameters are present from Step 1 so that
// extension needs no signature churn.

#ifndef CQ_IRPASS_FREE_POINT_H_
#define CQ_IRPASS_FREE_POINT_H_

#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Value.h"

namespace cq {

struct TaintSet;

// Classification of a terminal handle's disposition.
//   * Insert   — free here (`At` is the insertion point, never null).
//   * Measured — a measurement consumes the handle; no free (Step 3).
//   * Escaped  — the handle leaves the function (return / main / cq_invert) or
//                has no in-function users; no free, no diagnostic.
enum class FreePointKind { Insert, Measured, Escaped };

struct FreePoint {
  FreePointKind Kind;
  llvm::Instruction *At;  // valid iff Kind == Insert
};

// Compute the free point for `Terminal` in `F`. `PDT` is the function's
// post-dominator tree (built once by the caller). `taint` is consumed by the
// Step-3 measure/escape classification (unused in the Step-1 basic form).
FreePoint computeFreePoint(llvm::Value *Terminal, llvm::Function &F,
                           llvm::PostDominatorTree &PDT, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_FREE_POINT_H_
