/* cq_mid.h — transpiled-C ABI for Phase 1.
 *
 * Emitted into transpiled output by the rewriter; not part of the
 * user-facing surface in <CQ.h>. Declares the mid-level struct that
 * carries quantum signal at C-source boundaries (`qint_mid_t`) and
 * the per-width frontend intrinsics that clang -O1 -emit-llvm leaves
 * for the cq-lowering IR pass to rewrite into cqrt_ and cq_template_
 * runtime calls.
 *
 * Architecture references: docs/architecture.md §3 (mid-type), §6.1
 * (init), §6.2 (measure).
 */
#ifndef CQ_MID_H_
#define CQ_MID_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct { int32_t val; } qint_mid_t;

qint_mid_t cq_init_si32(int32_t value);
int32_t    cq_measure_si32(qint_mid_t q);

#ifdef __cplusplus
}
#endif

#endif  /* CQ_MID_H_ */
