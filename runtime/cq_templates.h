/* cq_templates.h — Phase 1 trace-only template stubs.
 *
 * Declares cq_template_add_i32, the lowering target for tainted
 * `add i32` instructions emitted by the cq-lowering IR pass. Returns
 * a fresh handle (via cqrt_alloc_handle in cq_runtime) so handle
 * numbering stays globally monotonic with libcq_runtime.
 *
 * Spec: phases/phase1/PLAN.md §4.3, §6.3.
 */
#ifndef CQ_TEMPLATES_H_
#define CQ_TEMPLATES_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Trace: "cq_template_add_i32(h<lhs>, h<rhs>) -> h<N>". Both args are
 * tainted quantum handles (Q+Q add). The IR pass dispatches to this
 * variant when both `add i32` operands are SSA values in the taint
 * set. */
int32_t cq_template_add_i32(int32_t lhs, int32_t rhs);

/* Trace: "cq_template_add_i32(h<lhs>, <rhs>) -> h<N>" — note the lack
 * of an `h` prefix on the rhs: it's a classical literal, not a handle.
 * Used for mixed Q+C add patterns (`quantum int d = a + 5;` or
 * `quantum int e = a + classic;` where classical operands fold to an
 * LLVM ConstantInt). The IR pass dispatches to this variant when the
 * rhs of a tainted `add i32` is a ConstantInt; the symbol's `_hl`
 * suffix (handle/literal) is an implementation detail (C lacks overloads)
 * — the trace prints the same "cq_template_add_i32" name as the
 * symmetric variant so user-facing trace logs stay consistent with
 * PLAN.md §4.7.1. Never promote the literal to a handle (would
 * conflict with the planned cq_alloc optimization).
 *
 * Trace line distinguishes by format alone: (h<N>, <M>) vs (h<N>, h<M>). */
int32_t cq_template_add_i32_hl(int32_t lhs_handle, int32_t rhs_literal);

#ifdef __cplusplus
}
#endif

#endif  /* CQ_TEMPLATES_H_ */
