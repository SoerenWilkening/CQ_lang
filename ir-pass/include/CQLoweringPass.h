// CQLoweringPass.h — Phase 1 production header for the cq-lowering IR pass.
//
// The pass walks each function, finds the front-end intrinsics that the
// rewriter+Clang leave behind (`@cq_init_i32`, `@cq_measure_i32`),
// propagates taint forward from init returns, and rewrites:
//
//   * `cq_init_i32(value)`                -> `cqrt_alloc_classical_i32(value)`
//   * tainted `add i32 %a, %b` (both SSA) -> `cq_template_add_i32(%a, %b)`
//   * tainted `add i32 %a, K` (K const)   -> `cq_template_add_i32_hl(%a, K)`
//     (Q+C mixed-operand dispatch; operands are swapped if K landed on
//     the lhs so the handle stays first)
//   * `cq_measure_i32(insertvalue ..)`    -> `cqrt_measure_i32(handle)`
//   * `cq_measure_i32(i32 %tainted)`      -> `cqrt_measure_i32(handle)`
//     (post -O1 flattened-struct shape, including the cast-rewriter
//     `(int)q` -> `cq_measure_i32(q)` lowering path)
//
// extractvalue/insertvalue traffic on the `%qint_mid_t` struct is removed
// so the post-pass IR contains only i32 handles. After lowering, the pass
// erases the front-end intrinsic declarations once they are use-less.
//
// Spec: phases/phase1/PLAN.md §4.5.

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
