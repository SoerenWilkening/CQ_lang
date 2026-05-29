// CQLoweringPass.h — production header for the cq-lowering IR pass.
//
// The pass walks each function, finds the front-end intrinsics that Clang
// leaves behind from `include/CQ.h` (`@cq_theta_<sfx>`, `@cq_phi_<sfx>`,
// `@cq_measure_<sfx>` — all on plain scalar SSA), propagates taint forward
// from theta returns, and rewrites:
//
//   * `cq_theta_si32(value, θ)` (classical operand)
//                       -> `cqrt_alloc_i32(value)` + `cqrt_ry_i32(h, θ)`
//   * `cq_theta_si32(%h, θ)` (tainted/chained operand)
//                       -> `cqrt_ry_i32(%h, θ)` (no re-allocation)
//   * `cq_phi_si32(%h, φ)` (tainted operand)
//                       -> `cqrt_rz_i32(%h, φ)`; classical operand -> deleted
//   * tainted `add i32 %a, %b` where both are tainted (Q+Q)
//                       -> `cq_template_add_i32(%a, %b)`
//   * tainted `add i32 %a, %c` where one operand is classical (Q+C)
//                       -> `cq_template_add_i32_hl(%a, %c)`
//     (the dispatch uses taint-set membership rather than `isa<ConstantInt>`,
//     so non-constant classical operands — function args, runtime-loaded
//     values, globals — are also routed to `_hl`. Operands are swapped if
//     the classical side landed on the lhs so the handle stays first.)
//   * `cq_measure_si32(i32 %tainted)`     -> `cqrt_measure_i32(handle)`
//
// A theta result is RAUW'd to its i32 handle (the alloc result, or the
// tainted operand for a chained theta); the cross-type case (e.g. an f64
// theta result -> i32 handle) is laundered by erasure of the tainted users
// (IMPLEMENTATION.md §1). After lowering, the pass erases the front-end
// intrinsic declarations once they are use-less.

#ifndef CQ_IRPASS_CQ_LOWERING_PASS_H_
#define CQ_IRPASS_CQ_LOWERING_PASS_H_

#include "llvm/IR/PassManager.h"

namespace cq {

struct CQLoweringPass : llvm::PassInfoMixin<CQLoweringPass> {
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);

  // Per-function worker. Exposed for unit-level callers; the canonical
  // entry point is `run`.
  static bool runOnFunction(llvm::Function &F);
};

}  // namespace cq

#endif  // CQ_IRPASS_CQ_LOWERING_PASS_H_
