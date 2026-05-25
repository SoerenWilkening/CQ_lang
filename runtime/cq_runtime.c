/* cq_runtime.c — Phase 1 trace-only runtime stub.
 *
 * See cq_runtime.h and phases/phase1/PLAN.md §4.3 for the spec.
 *
 * Each entry point prints exactly one '\n'-terminated trace line to
 * stdout and flushes, so the trace stays well-ordered with any other
 * stdout traffic from the host binary. Trace-line format is fixed by
 * PLAN.md §4.3 and pinned by the future ctest target in bd issue -oln.
 *
 * cqrt_free's trace-line format: this module emits "cqrt_free(h<N>)"
 * with NO "-> void" suffix. The arrow notation in the PLAN.md format
 * exists to carry a return value; with no return there is nothing to
 * write after the parens, so we omit the arrow. Documented here so
 * the convention is discoverable from one place.
 */
#include "cq_runtime.h"

#include <stdio.h>

/* Process-global handle counter. Shared between cqrt_alloc_i32 here and
 * cq_template_add_i32 (templates module, bd issue -0np) via the
 * cqrt_alloc_handle() helper, so handles stay globally monotonic. */
static int32_t next_handle = 0;

int32_t cqrt_alloc_handle(void) {
    return next_handle++;
}

int32_t cqrt_alloc_i32(int32_t value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i32(%d) -> h%d\n", value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_measure_i32(int32_t handle) {
    printf("cqrt_measure_i32(h%d) -> 0\n", handle);
    fflush(stdout);
    return 0;
}

void cqrt_free(int32_t handle) {
    printf("cqrt_free(h%d)\n", handle);
    fflush(stdout);
}
