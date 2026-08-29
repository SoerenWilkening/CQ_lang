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
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Value.h"

namespace cq {

struct TaintSet;

// Can `BB` execute more than once — i.e. is it reachable from ITSELF? A plain
// successor DFS, deliberately NOT `LoopInfo::getLoopFor`. `LoopInfo` recognizes
// only NATURAL loops (a single back edge to a header that dominates the body),
// so an IRREDUCIBLE cycle (two entries, no dominating header) returns null from
// it while still executing its blocks K times. Every at-most-once proof in the
// uncompute layer — the reversal backstops AND this module's `kMsgLoopBackedge`
// loudness guard — has to key on THIS, not on `LoopInfo`, or the same physical
// hazard is loud in one CFG spelling and silent in another.
//
// HOISTED HERE from `Uncomputation.cpp`'s anonymous namespace by bd
// test_C_libtooling-4p7j's Rule-13 RE-review (finding G1), unchanged. It was a
// per-TU definition with three consumers inside `Uncomputation` while
// `FreePoint::blockInLoop` — a FOURTH consumer, in the loudness path rather than
// the reversal path — still asked `LoopInfo` alone: the natural-loop spelling of
// a backedge-crossing live range declined loudly, the irreducible spelling
// silently leaked. Re-spelling the DFS in `FreePoint` would have been the
// `railOf` / `isAbiQramStore` drift hazard again (Rule 14), so there is ONE
// definition and both modules ask it. `FreePoint.h` is its home because both
// consumers already include this header and both are asking a PLACEMENT
// question ("may this point run twice?").
//
// A strict SUPERSET of "in a natural loop", so tightening a guard onto it can
// only turn silence into loudness, never lower into decline for an acyclic CFG.
bool blockCanRepeat(llvm::BasicBlock *BB);

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
