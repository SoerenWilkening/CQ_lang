/* cq_templates.c — Phase 2 trace-only template stubs.
 *
 * See cq_templates.h and phases/phase2/PLAN.md §4.7, §6.6.
 *
 * Format conventions (PLAN §6.6, mirrors cq_runtime.c):
 *   - handle:  h<N>           (printed as %d of int32_t handle id)
 *   - ints:    %lld           (value cast to long long, uniform across
 *                              all int widths so the format string does
 *                              not fork per width)
 *   - floats:  %f             (default 6-digit precision; float promotes
 *                              to double via varargs)
 *   - _Bool:   %d             (printed as 0/1 — only the i1 _hl body)
 *
 * Every body: cqrt_alloc_handle() → printf → fflush(stdout) → return.
 */
#include "cq_templates.h"

#include "cq_runtime.h"

#include <stdio.h>

/* --- i1 --------------------------------------------------------------- */

int32_t cq_template_add_i1(int32_t a_handle, int32_t b_handle) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_add_i1(h%d, h%d) -> h%d\n", a_handle, b_handle, h);
    fflush(stdout);
    return h;
}

int32_t cq_template_add_i1_hl(int32_t a_handle, bool b_classical) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_add_i1_hl(h%d, %d) -> h%d\n", a_handle,
           (int)b_classical, h);
    fflush(stdout);
    return h;
}

/* --- i8 --------------------------------------------------------------- */

int32_t cq_template_add_i8(int32_t a_handle, int32_t b_handle) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_add_i8(h%d, h%d) -> h%d\n", a_handle, b_handle, h);
    fflush(stdout);
    return h;
}

int32_t cq_template_add_i8_hl(int32_t a_handle, int8_t b_classical) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_add_i8_hl(h%d, %lld) -> h%d\n", a_handle,
           (long long)b_classical, h);
    fflush(stdout);
    return h;
}

/* --- i16 -------------------------------------------------------------- */

int32_t cq_template_add_i16(int32_t a_handle, int32_t b_handle) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_add_i16(h%d, h%d) -> h%d\n", a_handle, b_handle, h);
    fflush(stdout);
    return h;
}

int32_t cq_template_add_i16_hl(int32_t a_handle, int16_t b_classical) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_add_i16_hl(h%d, %lld) -> h%d\n", a_handle,
           (long long)b_classical, h);
    fflush(stdout);
    return h;
}

/* --- i32 (Phase 1 carryover; Q+Q body unchanged) --------------------- */

int32_t cq_template_add_i32(int32_t lhs, int32_t rhs) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_add_i32(h%d, h%d) -> h%d\n", lhs, rhs, h);
    fflush(stdout);
    return h;
}

int32_t cq_template_add_i32_hl(int32_t lhs_handle, int32_t rhs_literal) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_add_i32_hl(h%d, %lld) -> h%d\n", lhs_handle,
           (long long)rhs_literal, h);
    fflush(stdout);
    return h;
}

/* --- i64 -------------------------------------------------------------- */

int32_t cq_template_add_i64(int32_t a_handle, int32_t b_handle) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_add_i64(h%d, h%d) -> h%d\n", a_handle, b_handle, h);
    fflush(stdout);
    return h;
}

int32_t cq_template_add_i64_hl(int32_t a_handle, int64_t b_classical) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_add_i64_hl(h%d, %lld) -> h%d\n", a_handle,
           (long long)b_classical, h);
    fflush(stdout);
    return h;
}

/* --- f32 -------------------------------------------------------------- */

int32_t cq_template_fadd_f32(int32_t a_handle, int32_t b_handle) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_fadd_f32(h%d, h%d) -> h%d\n", a_handle, b_handle, h);
    fflush(stdout);
    return h;
}

int32_t cq_template_fadd_f32_hl(int32_t a_handle, float b_classical) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_fadd_f32_hl(h%d, %f) -> h%d\n", a_handle,
           (double)b_classical, h);
    fflush(stdout);
    return h;
}

/* --- f64 -------------------------------------------------------------- */

int32_t cq_template_fadd_f64(int32_t a_handle, int32_t b_handle) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_fadd_f64(h%d, h%d) -> h%d\n", a_handle, b_handle, h);
    fflush(stdout);
    return h;
}

int32_t cq_template_fadd_f64_hl(int32_t a_handle, double b_classical) {
    int32_t h = cqrt_alloc_handle();
    printf("cq_template_fadd_f64_hl(h%d, %f) -> h%d\n", a_handle, b_classical,
           h);
    fflush(stdout);
    return h;
}
