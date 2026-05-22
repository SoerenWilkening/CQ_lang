/* CQ.h — Phase 1 user-facing header.
 *
 * Declares the quantum keyword and the minimum intrinsic surface for
 * Phase 1: cq_init_i32 (taint source) and cq_measure_i32 (taint sink).
 * Other widths and intrinsic families enter in later phases.
 *
 * Architecture references: docs/architecture.md §3 (mid-type), §6.1
 * (init), §6.2 (measure). */
#ifndef CQ_H_
#define CQ_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define quantum __attribute__((annotate("quantum")))

typedef struct { int32_t val; } qint_mid_t;

qint_mid_t cq_init_i32(int32_t value);
int32_t    cq_measure_i32(qint_mid_t q);

#ifdef __cplusplus
}
#endif

#endif  /* CQ_H_ */
