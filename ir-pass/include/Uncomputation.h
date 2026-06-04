// Uncomputation.h — Thin per-function orchestrator for Phase 5 (PRD §2.2/§2.8/
// §2.10). Wired as the LAST mutation in both CQLoweringPass entry points, so
// `taint` is in its final post-lowering state. Composes the Phase-5 units
// (ChainWalk / FreePoint / InShadowAdjoint) + the EmitInverse spine; owns only
// the target-set partition, terminal selection, and emit ordering.
//
// Step 1 is a CONSERVATIVE slice (no ChainWalk / no full FreePoint / no
// in-shadow yet): it emits the adjoint + `cqrt_free` ONLY for a rotation-only,
// single-register terminal handle — a `cqrt_alloc_<W>` result whose every user
// is an uncontrolled `cqrt_ry/rz_<W>` gate on the handle, with a non-escaping
// post-dominating last use. Every other terminal is left untouched, so the
// pass is live in both entry points from commit 1 without disturbing the
// existing suite. Later steps generalize selection (Step 2), placement /
// measure / escape classification (Step 3), and the in-shadow controlled
// adjoint nested in the Phase-4 flag bracket (Step 4).

#ifndef CQ_IRPASS_UNCOMPUTATION_H_
#define CQ_IRPASS_UNCOMPUTATION_H_

#include "llvm/IR/Module.h"

namespace cq {

class WidthDispatch;
struct TaintSet;

// Walk every non-declaration function in `M`; for each selected tainted
// terminal handle, emit its whole-chain adjoint at the SSA last-use point
// followed by `cqrt_free`. Reads `taint` in its final post-lowering state.
void uncompute(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_UNCOMPUTATION_H_
