/* test_trace.c — M2 acceptance gate.
 *
 * Drives the runtime + templates API directly and prints exactly the
 * trace from PLAN.md §4.3's worked example. Stdout is diff'd against
 * test_trace.expected.log via the runtime_trace_test ctest target.
 * This pins the trace-line format before the IR pass or e2e fixtures
 * begin to depend on it.
 */
#include "cq_runtime.h"
#include "cq_templates.h"

int main(void) {
    int32_t h_a = cqrt_alloc_classical_i32(3);
    int32_t h_b = cqrt_alloc_classical_i32(5);
    int32_t h_c = cq_template_add_i32(h_a, h_b);
    (void) cqrt_measure_i32(h_c);
    return 0;
}
