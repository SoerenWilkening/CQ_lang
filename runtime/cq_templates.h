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

/* Trace: "cq_template_add_i32(h<lhs>, h<rhs>) -> h<N>". Args are
 * symmetrically int32_t; by construction the IR pass passes handles
 * for both, so both render as h<N>. */
int32_t cq_template_add_i32(int32_t lhs, int32_t rhs);

#ifdef __cplusplus
}
#endif

#endif  /* CQ_TEMPLATES_H_ */
