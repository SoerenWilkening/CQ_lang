/* test_trace.c — runtime-stub acceptance gate (Phase 2 M06).
 *
 * Drives the runtime API directly and prints exactly the trace expected
 * by test_trace.expected.log; the runtime_trace_test ctest target diffs
 * the two byte-for-byte. This pins every alloc / measure / template /
 * free trace-line format before the IR pass or e2e fixtures begin to
 * consume them.
 *
 * Layout: Phase 1 carryover (i32 alloc + i32 Q+Q template add + i32
 * measure) runs first, preserving its original handle IDs (h0–h2) so
 * the existing worked-example slice of the golden is unchanged across
 * the M06 widening. The 6 new widths (i1, i8, i16, i64, f32, f64) then
 * each exercise their alloc → measure pair in declaration order; the
 * monotonic handle counter walks h3..h8 across the 6 new allocs. See
 * phases/phase2/PLAN.md §4.6 and §6.6.
 */
#include "cq_runtime.h"
#include "cq_templates.h"

int main(void) {
    /* --- Phase 1 carryover (i32 alloc/template/measure) ----------- */
    int32_t h_a = cqrt_alloc_i32(3);
    int32_t h_b = cqrt_alloc_i32(5);
    int32_t h_c = cq_template_add_i32(h_a, h_b);
    (void) cqrt_measure_i32(h_c);

    /* --- Phase 2 M06 widening: alloc + measure for each new width.
     * Order matches cq_runtime.h declaration order minus i32. */
    int32_t h_i1  = cqrt_alloc_i1(true);
    (void) cqrt_measure_i1(h_i1);

    int32_t h_i8  = cqrt_alloc_i8((int8_t)127);
    (void) cqrt_measure_i8(h_i8);

    int32_t h_i16 = cqrt_alloc_i16((int16_t)1024);
    (void) cqrt_measure_i16(h_i16);

    int32_t h_i64 = cqrt_alloc_i64((int64_t)9000000000);
    (void) cqrt_measure_i64(h_i64);

    int32_t h_f32 = cqrt_alloc_f32(3.14f);
    (void) cqrt_measure_f32(h_f32);

    int32_t h_f64 = cqrt_alloc_f64(2.718281828);
    (void) cqrt_measure_f64(h_f64);

    return 0;
}
