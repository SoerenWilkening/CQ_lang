/* The __bf16 side of selftest.c, compiled WITHOUT FENV_ACCESS: clang 19 cannot compile strict FP ops on
 * bfloat for x86 ("soft promote"), and in a strict function a __bf16 argument or result is converted
 * through float, which changes the bits it carries (a bf16 subnormal arrived as 0). Here every value
 * crosses as its bit pattern.
 *   hb_*: the host's conversions to __bf16 (compiler-rt calls: they ignore the mode, raise no flags);
 *   lb_*: calls of the roots that take or return __bf16. */
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "cqsf_roots.h"

typedef uint64_t u64;
static u64 Bb(__bf16 v) { uint16_t x; memcpy(&x, &v, 2); return x; }
static __bf16 Bf(u64 b) { uint16_t x = (uint16_t)b; __bf16 r; memcpy(&r, &x, 2); return r; }
static float S(u64 b) { uint32_t x = (uint32_t)b; float r; memcpy(&r, &x, 4); return r; }
static double D(u64 b) { double r; memcpy(&r, &b, 8); return r; }
static u64 Sb(float v) { uint32_t x; memcpy(&x, &v, 4); return x; }
static u64 Db(double v) { u64 x; memcpy(&x, &v, 8); return x; }

u64 hb_from_s(u64 a) { return Bb((__bf16)S(a)); }
u64 hb_from_d(u64 a) { return Bb((__bf16)D(a)); }
u64 hb_from_i64(int64_t v) { return Bb((__bf16)v); }
u64 hb_from_u64(uint64_t v) { return Bb((__bf16)v); }
u64 hb_from_f(float v) { return Bb((__bf16)v); }

bool lb_is_fpclass(u64 a, uint32_t mask) { return cqsf_is_fpclass_bf16(Bf(a), mask); }
u64 lb_fpext_f32(u64 a) { return Sb(cqsf_fpext_bf16_to_f32(Bf(a))); }
uint32_t lb_fpext_f32_x(u64 a) { return cqsf_fpext_bf16_to_f32_x(Bf(a)); }
u64 lb_fpext_f64(u64 a) { return Db(cqsf_fpext_bf16_to_f64(Bf(a))); }
uint32_t lb_fpext_f64_x(u64 a) { return cqsf_fpext_bf16_to_f64_x(Bf(a)); }
u64 lb_fptrunc_s(u64 a) { return Bb(cqsf_fptrunc_f32_to_bf16(S(a))); }
u64 lb_fptrunc_s_m(u64 a, uint32_t m) { return Bb(cqsf_fptrunc_f32_to_bf16_m(S(a), m)); }
uint32_t lb_fptrunc_s_x(u64 a, uint32_t m) { return cqsf_fptrunc_f32_to_bf16_x(S(a), m); }
u64 lb_fptrunc_d(u64 a) { return Bb(cqsf_fptrunc_f64_to_bf16(D(a))); }
u64 lb_fptrunc_d_m(u64 a, uint32_t m) { return Bb(cqsf_fptrunc_f64_to_bf16_m(D(a), m)); }
uint32_t lb_fptrunc_d_x(u64 a, uint32_t m) { return cqsf_fptrunc_f64_to_bf16_x(D(a), m); }

#define ITOB(N, TS, TU)                                                                                  \
u64 lb_sitofp_##N(TS v) { return Bb(cqsf_sitofp_i##N##_to_bf16(v)); }                                  \
u64 lb_sitofp_##N##_m(TS v, uint32_t m) { return Bb(cqsf_sitofp_i##N##_to_bf16_m(v, m)); }             \
uint32_t lb_sitofp_##N##_x(TS v, uint32_t m) { return cqsf_sitofp_i##N##_to_bf16_x(v, m); }            \
u64 lb_uitofp_##N(TU v) { return Bb(cqsf_uitofp_i##N##_to_bf16(v)); }                                  \
u64 lb_uitofp_##N##_m(TU v, uint32_t m) { return Bb(cqsf_uitofp_i##N##_to_bf16_m(v, m)); }             \
uint32_t lb_uitofp_##N##_x(TU v, uint32_t m) { return cqsf_uitofp_i##N##_to_bf16_x(v, m); }
ITOB(1, bool, bool) ITOB(8, int8_t, uint8_t) ITOB(16, int16_t, uint16_t) ITOB(32, int32_t, uint32_t) ITOB(64, int64_t, uint64_t)

/* bf16 -> int: value and flags of each of the eight targets, in the order of selftest.c's F2I. */
void lb_fptoint(u64 a, u64 v[8], uint32_t f[8]) {
    __bf16 x = Bf(a);
    v[0] = (uint8_t)cqsf_fptosi_bf16_to_i8(x);   f[0] = cqsf_fptosi_bf16_to_i8_x(x);
    v[1] = (uint16_t)cqsf_fptosi_bf16_to_i16(x); f[1] = cqsf_fptosi_bf16_to_i16_x(x);
    v[2] = (uint32_t)cqsf_fptosi_bf16_to_i32(x); f[2] = cqsf_fptosi_bf16_to_i32_x(x);
    v[3] = (u64)cqsf_fptosi_bf16_to_i64(x);      f[3] = cqsf_fptosi_bf16_to_i64_x(x);
    v[4] = cqsf_fptoui_bf16_to_i8(x);            f[4] = cqsf_fptoui_bf16_to_i8_x(x);
    v[5] = cqsf_fptoui_bf16_to_i16(x);           f[5] = cqsf_fptoui_bf16_to_i16_x(x);
    v[6] = cqsf_fptoui_bf16_to_i32(x);           f[6] = cqsf_fptoui_bf16_to_i32_x(x);
    v[7] = cqsf_fptoui_bf16_to_i64(x);           f[7] = cqsf_fptoui_bf16_to_i64_x(x);
}
