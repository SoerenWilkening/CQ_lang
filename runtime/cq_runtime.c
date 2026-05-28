/* cq_runtime.c — Phase 2 trace-only runtime stub.
 *
 * See cq_runtime.h for the spec.
 *
 * Each entry point prints exactly one '\n'-terminated trace line to
 * stdout and flushes, so the trace stays well-ordered with any other
 * stdout traffic from the host binary. Trace-line formats are pinned
 * by PLAN.md §6.6 and locked byte-exact by runtime_trace_test (the
 * test_trace driver + test_trace.expected.log golden).
 *
 * Format conventions:
 *   - handle:  h<N>           (printed as %d of int32_t handle id)
 *   - ints:    %lld           (value cast to long long, uniform across
 *                              all int widths so the format string does
 *                              not fork per width)
 *   - floats:  %f             (default 6-digit precision; float promotes
 *                              to double via varargs)
 *   - _Bool:   %d             (printed as 0/1 — only the i1 alloc body)
 *
 * Measure bodies print the zero return value as a literal in the trace
 * ("0" for ints, "0.000000" for floats). This is byte-identical to
 * formatting (long long)0 with %lld and 0.0 with %f respectively, and
 * matches the Phase 1 cqrt_measure_i32 convention.
 *
 * cqrt_free's trace-line format: this module emits "cqrt_free(h<N>)"
 * with NO "-> void" suffix. The arrow notation in the PLAN.md format
 * exists to carry a return value; with no return there is nothing to
 * write after the parens, so we omit the arrow. Documented here so
 * the convention is discoverable from one place.
 */
#include "cq_runtime.h"

#include <stdio.h>

/* Process-global handle counter. Shared between every cqrt_alloc_<W>
 * here and every cq_template_add_<W>* in the templates module via the
 * cqrt_alloc_handle() helper, so handles stay globally monotonic
 * regardless of which width / which module issues them. */
static int32_t next_handle = 0;

int32_t cqrt_alloc_handle(void) {
    return next_handle++;
}

/* ---------------------------------------------------------------------
 * Allocation bodies — one per width.
 * ------------------------------------------------------------------- */

int32_t cqrt_alloc_i1(bool value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i1(%d) -> h%d\n", (int)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_i8(int8_t value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i8(%lld) -> h%d\n", (long long)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_i16(int16_t value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i16(%lld) -> h%d\n", (long long)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_i32(int32_t value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i32(%lld) -> h%d\n", (long long)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_i64(int64_t value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i64(%lld) -> h%d\n", (long long)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_f32(float value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_f32(%f) -> h%d\n", (double)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_f64(double value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_f64(%f) -> h%d\n", value, h);
    fflush(stdout);
    return h;
}

/* ---------------------------------------------------------------------
 * Measure bodies — one per width. Return zero of the matching width
 * (Phase 2 runtime is trace-only, no simulation). Zero is printed as
 * a literal to keep all measure bodies uniform and match the Phase 1
 * cqrt_measure_i32 convention; byte-identical to %lld of (long long)0
 * for ints and %f of 0.0 for floats.
 * ------------------------------------------------------------------- */

bool cqrt_measure_i1(int32_t handle) {
    printf("cqrt_measure_i1(h%d) -> 0\n", handle);
    fflush(stdout);
    return false;
}

int8_t cqrt_measure_i8(int32_t handle) {
    printf("cqrt_measure_i8(h%d) -> 0\n", handle);
    fflush(stdout);
    return 0;
}

int16_t cqrt_measure_i16(int32_t handle) {
    printf("cqrt_measure_i16(h%d) -> 0\n", handle);
    fflush(stdout);
    return 0;
}

int32_t cqrt_measure_i32(int32_t handle) {
    printf("cqrt_measure_i32(h%d) -> 0\n", handle);
    fflush(stdout);
    return 0;
}

int64_t cqrt_measure_i64(int32_t handle) {
    printf("cqrt_measure_i64(h%d) -> 0\n", handle);
    fflush(stdout);
    return 0;
}

float cqrt_measure_f32(int32_t handle) {
    printf("cqrt_measure_f32(h%d) -> 0.000000\n", handle);
    fflush(stdout);
    return 0.0f;
}

double cqrt_measure_f64(int32_t handle) {
    printf("cqrt_measure_f64(h%d) -> 0.000000\n", handle);
    fflush(stdout);
    return 0.0;
}

/* ---------------------------------------------------------------------
 * Free — width-irrelevant.
 * ------------------------------------------------------------------- */

void cqrt_free(int32_t handle) {
    printf("cqrt_free(h%d)\n", handle);
    fflush(stdout);
}
