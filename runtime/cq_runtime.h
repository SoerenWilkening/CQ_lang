/* cq_runtime.h — Phase 1 trace-only runtime stub.
 *
 * Declares the cqrt_* lowering targets used by the IR pass:
 *   - cqrt_alloc_classical_i32 : taint-source lowering (cq_init_i32 -> here)
 *   - cqrt_measure_i32         : taint-sink lowering   (cq_measure_i32 -> here)
 *   - cqrt_free                : declared, unused in Phase 1
 *
 * Each call prints exactly one trace line to stdout in the format
 *     <symbol>(<arg1>[, <arg2>...]) -> <return>
 * (or "<symbol>(<args>)" for cqrt_free, which has no return value).
 * Handles are printed as h<N> where N is a monotonically increasing
 * counter starting at 0.
 *
 * Spec: phases/phase1/PLAN.md §4.3.
 */
#ifndef CQ_RUNTIME_H_
#define CQ_RUNTIME_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Taint-source lowering. Returns a fresh monotonically-increasing
 * handle. Trace: "cqrt_alloc_classical_i32(<value>) -> h<N>". */
int32_t cqrt_alloc_classical_i32(int32_t value);

/* Taint-sink lowering. Always returns 0 in Phase 1 (per PRD).
 * Trace: "cqrt_measure_i32(h<handle>) -> 0". */
int32_t cqrt_measure_i32(int32_t handle);

/* Declared but unused in Phase 1; reserved for later lifetime work.
 * Trace: "cqrt_free(h<handle>)" (no return-value suffix). */
void cqrt_free(int32_t handle);

/* Internal helper: returns the next monotonically increasing handle.
 * Used by cqrt_alloc_classical_i32 here and cq_template_add_i32 in the
 * future templates module to keep handle numbering globally monotonic.
 * Not part of the user-facing CQ.h surface. */
int32_t cqrt_alloc_handle(void);

#ifdef __cplusplus
}
#endif

#endif  /* CQ_RUNTIME_H_ */
