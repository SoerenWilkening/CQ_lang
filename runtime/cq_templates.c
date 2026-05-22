/* cq_templates.c — Phase 1 trace-only template stubs.
 *
 * See cq_templates.h and phases/phase1/PLAN.md §4.3, §6.3.
 */
#include "cq_templates.h"

#include "cq_runtime.h"

#include <stdio.h>

int32_t cq_template_add_i32(int32_t lhs, int32_t rhs) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_add_i32(h%d, h%d) -> h%d\n", lhs, rhs, h);
    fflush(stdout);
    return h;
}
