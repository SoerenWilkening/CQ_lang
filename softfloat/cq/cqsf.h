/* cqsf.h: the CQ float templates as functions of bit patterns, on top of the patched SoftFloat.
 *
 * Every operation is `sfx_<op>_<W>(struct sf_ctx *sf_ctx, operands...)`: operands and results are bit
 * patterns (uint16_t f16/bf16, uint32_t f32, uint64_t f64, struct extFloat80M f80), c carries the
 * SoftFloat rounding mode in and the SoftFloat exception flags out. The semantics are CONSTRUCTION_RULES
 * §1.2 and §2 (CQ_spec); where x86-64 LLVM 19 -O1 code fixes a value, the comment says so. The roots
 * (cqsf_roots.c, generated) wrap these with the C float types of the template operands, so a lowered
 * root takes and returns rails of the template's own widths.
 *
 * Every function here and in SoftFloat is always_inline (cqsf_roots.c): after clang -O1 the context
 * is scalar SSA and no root touches memory. */
#ifndef CQSF_H
#define CQSF_H

#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

/* ---- the environment ------------------------------------------------------------------------ */

/* The x86-64 FE_* rounding value (bits 10-11: 0 nearest-even, 1 down, 2 up, 3 toward zero; the other
 * bits ignored, CR §1.2) as a SoftFloat rounding mode (near_even 0, min 2, max 3, minMag 1). */
static inline uint_fast8_t cqsf_mode(uint32_t fe) { return (uint_fast8_t)((0x1320u >> (((fe >> 10) & 3u) * 4u)) & 0xFu); }

/* SoftFloat flags (inexact 1, underflow 2, overflow 4, infinite 8, invalid 16) as the x86 exception
 * bits of CR §1.2 (INVALID 1, DIVBYZERO 4, OVERFLOW 8, UNDERFLOW 16, INEXACT 32). SoftFloat raises
 * underflow only with inexact and detects tininess after rounding (the patch fixes it), as x86 does. */
static inline uint32_t cqsf_x86flags(uint_fast8_t f) {
    return ((f & softfloat_flag_invalid) ? 1u : 0u) | ((f & softfloat_flag_infinite) ? 4u : 0u) |
           ((f & softfloat_flag_overflow) ? 8u : 0u) | ((f & softfloat_flag_underflow) ? 16u : 0u) |
           ((f & softfloat_flag_inexact) ? 32u : 0u);
}

/* ---- per-format bit tests ------------------------------------------------------------------- */

#define CQSF_SIGN16 UINT16_C(0x8000)
#define CQSF_SIGN32 UINT32_C(0x80000000)
#define CQSF_SIGN64 UINT64_C(0x8000000000000000)
#define CQSF_QUIET_f16 UINT16_C(0x0200)
#define CQSF_QUIET_f32 UINT32_C(0x00400000)
#define CQSF_QUIET_f64 UINT64_C(0x0008000000000000)

static inline bool cqsf_isnan_f16(uint16_t a) { return isNaNF16UI(a); }
static inline bool cqsf_isnan_bf16(uint16_t a) { return isNaNBF16UI(a); }
static inline bool cqsf_isnan_f32(uint32_t a) { return isNaNF32UI(a); }
static inline bool cqsf_isnan_f64(uint64_t a) { return isNaNF64UI(a); }
static inline bool cqsf_issnan_f16(uint16_t a) { return softfloat_isSigNaNF16UI(a); }
static inline bool cqsf_issnan_f32(uint32_t a) { return softfloat_isSigNaNF32UI(a); }
static inline bool cqsf_issnan_f64(uint64_t a) { return softfloat_isSigNaNF64UI(a); }

/* ---- arithmetic: f16, f32, f64 -------------------------------------------------------------- */

#define CQSF_ARITH(W, U, T, SIGN)                                                                        \
static inline U sfx_fadd_##W(struct sf_ctx *sf_ctx, U a, U b) { return W##_add(sf_ctx, (T){a}, (T){b}).v; }       \
static inline U sfx_fsub_##W(struct sf_ctx *sf_ctx, U a, U b) { return W##_sub(sf_ctx, (T){a}, (T){b}).v; }       \
static inline U sfx_fmul_##W(struct sf_ctx *sf_ctx, U a, U b) { return W##_mul(sf_ctx, (T){a}, (T){b}).v; }       \
static inline U sfx_fdiv_##W(struct sf_ctx *sf_ctx, U a, U b) { return W##_div(sf_ctx, (T){a}, (T){b}).v; }       \
static inline U sfx_sqrt_##W(struct sf_ctx *sf_ctx, U a) { return W##_sqrt(sf_ctx, (T){a}).v; }                   \
/* fma: a NaN operand gives the first NaN operand quieted (CR §2), INVALID only for an sNaN: x86      \
 * vfmadd returns a quiet NaN c for 0 * Inf + c; SoftFloat would raise INVALID and give the default. */ \
static inline U sfx_fma_##W(struct sf_ctx *sf_ctx, U a, U b, U d) {                                    \
    if (cqsf_isnan_##W(a) || cqsf_isnan_##W(b) || cqsf_isnan_##W(d)) {                                 \
        if (cqsf_issnan_##W(a) || cqsf_issnan_##W(b) || cqsf_issnan_##W(d)) softfloat_raiseFlags(softfloat_flag_invalid); \
        return (cqsf_isnan_##W(a) ? a : cqsf_isnan_##W(b) ? b : d) | (U)CQSF_QUIET_##W; \
    }                                                                                                   \
    return W##_mulAdd(sf_ctx, (T){a}, (T){b}, (T){d}).v;                                                \
}                                                                                                       \
/* frem is C fmod (CR §2): r = IEEE remainder; when r is nonzero and its sign differs from a's,      \
 * fmod = r + copysign(|b|, a), an exact sum (its value x - n*y is representable), so no flag. */    \
static inline U sfx_frem_##W(struct sf_ctx *sf_ctx, U a, U b) {                                            \
    U r = W##_rem(sf_ctx, (T){a}, (T){b}).v;                                                                 \
    if (cqsf_isnan_##W(r) || !(r & (U)~SIGN) || ((r ^ a) & SIGN) == 0) return r;                        \
    return W##_add(sf_ctx, (T){r}, (T){(U)((b & (U)~SIGN) | (a & SIGN))}).v;                                 \
}                                                                                                       \
/* fmax/fmin (llvm.maxnum/minnum, CR §2): isnan(a) ? b : isnan(b) ? a : (b > a ? b : a), min with <;  \
 * equal values give a, two NaNs give b unchanged. INVALID iff an operand is a signalling NaN (CR §2: \
 * IEEE maxNum, native leaves it to libm). */                                                         \
static inline U sfx_fmax_##W(struct sf_ctx *sf_ctx, U a, U b) {                                            \
    if (cqsf_issnan_##W(a) || cqsf_issnan_##W(b)) softfloat_raiseFlags(softfloat_flag_invalid);       \
    if (cqsf_isnan_##W(a)) return b;                                                                    \
    if (cqsf_isnan_##W(b)) return a;                                                                    \
    return W##_lt_quiet(sf_ctx, (T){a}, (T){b}) ? b : a;                                                     \
}                                                                                                       \
static inline U sfx_fmin_##W(struct sf_ctx *sf_ctx, U a, U b) {                                            \
    if (cqsf_issnan_##W(a) || cqsf_issnan_##W(b)) softfloat_raiseFlags(softfloat_flag_invalid);       \
    if (cqsf_isnan_##W(a)) return b;                                                                    \
    if (cqsf_isnan_##W(b)) return a;                                                                    \
    return W##_lt_quiet(sf_ctx, (T){b}, (T){a}) ? b : a;                                                     \
}                                                                                                       \
/* The rounding ops (CR §2): floor, ceil, trunc and round never raise INEXACT (x86 roundsd with the   \
 * precision exception suppressed; C floor); rint rounds in the context's mode and raises it. */      \
static inline U sfx_floor_##W(struct sf_ctx *sf_ctx, U a) { return W##_roundToInt(sf_ctx, (T){a}, softfloat_round_min, false).v; } \
static inline U sfx_ceil_##W(struct sf_ctx *sf_ctx, U a) { return W##_roundToInt(sf_ctx, (T){a}, softfloat_round_max, false).v; } \
static inline U sfx_trunc_##W(struct sf_ctx *sf_ctx, U a) { return W##_roundToInt(sf_ctx, (T){a}, softfloat_round_minMag, false).v; } \
static inline U sfx_round_##W(struct sf_ctx *sf_ctx, U a) { return W##_roundToInt(sf_ctx, (T){a}, softfloat_round_near_maxMag, false).v; } \
static inline U sfx_rint_##W(struct sf_ctx *sf_ctx, U a) { return W##_roundToInt(sf_ctx, (T){a}, sf_ctx->roundingMode, true).v; } \
/* fcmp: the quiet compares (INVALID only for a signalling NaN, x86 ucomis); fcmps: the signalling  \
 * ones (INVALID for any NaN, x86 comis). The value is the same for both. */                          \
static inline bool sfx_cmpq_eq_##W(struct sf_ctx *sf_ctx, U a, U b) { return W##_eq(sf_ctx, (T){a}, (T){b}); }   \
static inline bool sfx_cmpq_lt_##W(struct sf_ctx *sf_ctx, U a, U b) { return W##_lt_quiet(sf_ctx, (T){a}, (T){b}); } \
static inline bool sfx_cmpq_le_##W(struct sf_ctx *sf_ctx, U a, U b) { return W##_le_quiet(sf_ctx, (T){a}, (T){b}); } \
static inline bool sfx_cmps_eq_##W(struct sf_ctx *sf_ctx, U a, U b) { return W##_eq_signaling(sf_ctx, (T){a}, (T){b}); } \
static inline bool sfx_cmps_lt_##W(struct sf_ctx *sf_ctx, U a, U b) { return W##_lt(sf_ctx, (T){a}, (T){b}); }   \
static inline bool sfx_cmps_le_##W(struct sf_ctx *sf_ctx, U a, U b) { return W##_le(sf_ctx, (T){a}, (T){b}); }

CQSF_ARITH(f16, uint16_t, float16_t, CQSF_SIGN16)
CQSF_ARITH(f32, uint32_t, float32_t, CQSF_SIGN32)
CQSF_ARITH(f64, uint64_t, float64_t, CQSF_SIGN64)

/* The fcmp predicates from eq/lt/le (q: quiet, s: signalling). Each raises its compare's flags once
 * (every predicate evaluates at least one compare of the operand pair, which raises the same bits). */
#define CQSF_PREDS(W, U, K)                                                                              \
static inline bool sfx_fcmp##K##_oeq_##W(struct sf_ctx *sf_ctx, U a, U b) { return sfx_cmp##K##_eq_##W(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_ogt_##W(struct sf_ctx *sf_ctx, U a, U b) { return sfx_cmp##K##_lt_##W(sf_ctx, b, a); } \
static inline bool sfx_fcmp##K##_oge_##W(struct sf_ctx *sf_ctx, U a, U b) { return sfx_cmp##K##_le_##W(sf_ctx, b, a); } \
static inline bool sfx_fcmp##K##_olt_##W(struct sf_ctx *sf_ctx, U a, U b) { return sfx_cmp##K##_lt_##W(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_ole_##W(struct sf_ctx *sf_ctx, U a, U b) { return sfx_cmp##K##_le_##W(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_one_##W(struct sf_ctx *sf_ctx, U a, U b) {                                \
    bool l = sfx_cmp##K##_lt_##W(sf_ctx, a, b); return sfx_cmp##K##_lt_##W(sf_ctx, b, a) || l; }                 \
static inline bool sfx_fcmp##K##_ord_##W(struct sf_ctx *sf_ctx, U a, U b) {                                \
    (void)sfx_cmp##K##_eq_##W(sf_ctx, a, b); return !cqsf_isnan_##W(a) && !cqsf_isnan_##W(b); }             \
static inline bool sfx_fcmp##K##_uno_##W(struct sf_ctx *sf_ctx, U a, U b) { return !sfx_fcmp##K##_ord_##W(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_ueq_##W(struct sf_ctx *sf_ctx, U a, U b) {                                \
    bool e = sfx_cmp##K##_eq_##W(sf_ctx, a, b); return e || cqsf_isnan_##W(a) || cqsf_isnan_##W(b); }       \
static inline bool sfx_fcmp##K##_ugt_##W(struct sf_ctx *sf_ctx, U a, U b) { return !sfx_cmp##K##_le_##W(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_uge_##W(struct sf_ctx *sf_ctx, U a, U b) { return !sfx_cmp##K##_lt_##W(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_ult_##W(struct sf_ctx *sf_ctx, U a, U b) { return !sfx_cmp##K##_le_##W(sf_ctx, b, a); } \
static inline bool sfx_fcmp##K##_ule_##W(struct sf_ctx *sf_ctx, U a, U b) { return !sfx_cmp##K##_lt_##W(sf_ctx, b, a); } \
static inline bool sfx_fcmp##K##_une_##W(struct sf_ctx *sf_ctx, U a, U b) { return !sfx_cmp##K##_eq_##W(sf_ctx, a, b); }

CQSF_PREDS(f16, uint16_t, q) CQSF_PREDS(f16, uint16_t, s)
CQSF_PREDS(f32, uint32_t, q) CQSF_PREDS(f32, uint32_t, s)
CQSF_PREDS(f64, uint64_t, q) CQSF_PREDS(f64, uint64_t, s)

/* is_fpclass (CR §2): a pure bit test, no flag. LLVM's bit order: 0 sNaN, 1 qNaN, 2 -Inf, 3 -normal,
 * 4 -subnormal, 5 -0, 6 +0, 7 +subnormal, 8 +normal, 9 +Inf. */
#define CQSF_CLASS(W, U, EXPMASK, FRACMASK, QUIET, SIGN)                                                 \
static inline bool sfx_is_fpclass_##W(struct sf_ctx *sf_ctx, U a, uint32_t mask) {                          \
    (void)sf_ctx;                                                                                            \
    U e = a & (U)EXPMASK, f = a & (U)FRACMASK; bool neg = (a & (U)SIGN) != 0; unsigned bit;             \
    if (e == (U)EXPMASK) bit = f ? ((f & (U)QUIET) ? 1u : 0u) : (neg ? 2u : 9u);                         \
    else if (e) bit = neg ? 3u : 8u;                                                                    \
    else bit = f ? (neg ? 4u : 7u) : (neg ? 5u : 6u);                                                   \
    return (mask >> bit) & 1u;                                                                          \
}
CQSF_CLASS(f16, uint16_t, 0x7C00, 0x03FF, 0x0200, 0x8000)
CQSF_CLASS(bf16, uint16_t, 0x7F80, 0x007F, 0x0040, 0x8000)
CQSF_CLASS(f32, uint32_t, 0x7F800000, 0x007FFFFF, 0x00400000, 0x80000000)
CQSF_CLASS(f64, uint64_t, UINT64_C(0x7FF0000000000000), UINT64_C(0x000FFFFFFFFFFFFF), UINT64_C(0x0008000000000000), UINT64_C(0x8000000000000000))

/* ---- fp to fp ------------------------------------------------------------------------------- */

static inline uint32_t sfx_fpext_f16_to_f32(struct sf_ctx *sf_ctx, uint16_t a) { return f16_to_f32(sf_ctx, (float16_t){a}).v; }
static inline uint64_t sfx_fpext_f16_to_f64(struct sf_ctx *sf_ctx, uint16_t a) { return f16_to_f64(sf_ctx, (float16_t){a}).v; }
static inline uint64_t sfx_fpext_f32_to_f64(struct sf_ctx *sf_ctx, uint32_t a) { return f32_to_f64(sf_ctx, (float32_t){a}).v; }
/* bf16 -> f32 is inline, a bare shift: an sNaN stays signalling, no flag (CR §2). bf16 -> f64 is that
 * shift then f32 -> f64. */
static inline uint32_t sfx_fpext_bf16_to_f32(struct sf_ctx *sf_ctx, uint16_t a) { (void)sf_ctx; return (uint32_t)a << 16; }
static inline uint64_t sfx_fpext_bf16_to_f64(struct sf_ctx *sf_ctx, uint16_t a) { return f32_to_f64(sf_ctx, (float32_t){(uint32_t)a << 16}).v; }
static inline uint16_t sfx_fptrunc_f32_to_f16(struct sf_ctx *sf_ctx, uint32_t a) { return f32_to_f16(sf_ctx, (float32_t){a}).v; }
static inline uint16_t sfx_fptrunc_f64_to_f16(struct sf_ctx *sf_ctx, uint64_t a) { return f64_to_f16(sf_ctx, (float64_t){a}).v; }
static inline uint32_t sfx_fptrunc_f64_to_f32(struct sf_ctx *sf_ctx, uint64_t a) { return f64_to_f32(sf_ctx, (float64_t){a}).v; }
static inline uint16_t sfx_fptrunc_f32_to_bf16(struct sf_ctx *sf_ctx, uint32_t a) { return f32_to_bf16(sf_ctx, (float32_t){a}).v; }
static inline uint16_t sfx_fptrunc_f64_to_bf16(struct sf_ctx *sf_ctx, uint64_t a) { return f64_to_bf16(sf_ctx, (float64_t){a}).v; }

/* ---- int to fp (sitofp/uitofp from at most 64 bits; the operand is sign- or zero-extended) ---- */

static inline uint16_t sfx_si_to_f16(struct sf_ctx *sf_ctx, int64_t x) { return i64_to_f16(sf_ctx, x).v; }
static inline uint32_t sfx_si_to_f32(struct sf_ctx *sf_ctx, int64_t x) { return i64_to_f32(sf_ctx, x).v; }
static inline uint64_t sfx_si_to_f64(struct sf_ctx *sf_ctx, int64_t x) { return i64_to_f64(sf_ctx, x).v; }
static inline uint16_t sfx_ui_to_f16(struct sf_ctx *sf_ctx, uint64_t x) { return ui64_to_f16(sf_ctx, x).v; }
static inline uint32_t sfx_ui_to_f32(struct sf_ctx *sf_ctx, uint64_t x) { return ui64_to_f32(sf_ctx, x).v; }
static inline uint64_t sfx_ui_to_f64(struct sf_ctx *sf_ctx, uint64_t x) { return ui64_to_f64(sf_ctx, x).v; }
/* To bf16 (CR §2): iN -> f32 rounded, then that f32 -> bf16, two roundings. */
static inline uint16_t sfx_si_to_bf16(struct sf_ctx *sf_ctx, int64_t x) { return f32_to_bf16(sf_ctx, i64_to_f32(sf_ctx, x)).v; }
static inline uint16_t sfx_ui_to_bf16(struct sf_ctx *sf_ctx, uint64_t x) { return f32_to_bf16(sf_ctx, ui64_to_f32(sf_ctx, x)).v; }

/* ---- fp to int: x86-64 LLVM 19 -O1 (CR §2) ---------------------------------------------------
 * c32/c64 are cvtt to i32/i64 with the indefinite INT_MIN of that width (8086-SSE's i32_fromNaN and
 * friends), INEXACT for a fraction. fptosi i8/i16 = trunc(c32), i32 = c32, i64 = c64; fptoui
 * i8/i16 = trunc(c32), i32 = trunc(c64), i64 = r1 | (r2 & (r1 >>s 63)), r1 = c64(x),
 * r2 = c64(x - 2^63). f16 and bf16 go through f32 (exact). */
static inline int32_t cqsf_c32_f32(struct sf_ctx *sf_ctx, uint32_t a) { return (int32_t)f32_to_i32_r_minMag(sf_ctx, (float32_t){a}, true); }
static inline int64_t cqsf_c64_f32(struct sf_ctx *sf_ctx, uint32_t a) { return (int64_t)f32_to_i64_r_minMag(sf_ctx, (float32_t){a}, true); }
static inline int32_t cqsf_c32_f64(struct sf_ctx *sf_ctx, uint64_t a) { return (int32_t)f64_to_i32_r_minMag(sf_ctx, (float64_t){a}, true); }
static inline int64_t cqsf_c64_f64(struct sf_ctx *sf_ctx, uint64_t a) { return (int64_t)f64_to_i64_r_minMag(sf_ctx, (float64_t){a}, true); }
/* The value is the -O1 formula. The _exc bits are those of x86-64 strict code (llvm.experimental.
 * constrained.fptoui, no AVX-512): x - (x >= 2^63 ? 2^63 : 0), then one cvtt (the subtraction is inexact only for huge x), so
 * 1.0 raises nothing and -1.0 raises nothing (it is in i64 range). */
static inline uint64_t cqsf_u64_f32(struct sf_ctx *sf_ctx, uint32_t a) {
    struct sf_ctx t = {sf_ctx->roundingMode, 0};
    float32_t two63 = {UINT32_C(0x5F000000)};
    int64_t r1 = cqsf_c64_f32(&t, a);
    int64_t r2 = cqsf_c64_f32(&t, f32_sub(&t, (float32_t){a}, two63).v);
    bool ge = f32_le_quiet(&t, two63, (float32_t){a});
    (void)cqsf_c64_f32(sf_ctx, ge ? f32_sub(sf_ctx, (float32_t){a}, two63).v : a);
    return (uint64_t)(r1 | (r2 & (r1 >> 63)));
}
static inline uint64_t cqsf_u64_f64(struct sf_ctx *sf_ctx, uint64_t a) {
    struct sf_ctx t = {sf_ctx->roundingMode, 0};
    float64_t two63 = {UINT64_C(0x43E0000000000000)};
    int64_t r1 = cqsf_c64_f64(&t, a);
    int64_t r2 = cqsf_c64_f64(&t, f64_sub(&t, (float64_t){a}, two63).v);
    bool ge = f64_le_quiet(&t, two63, (float64_t){a});
    (void)cqsf_c64_f64(sf_ctx, ge ? f64_sub(sf_ctx, (float64_t){a}, two63).v : a);
    return (uint64_t)(r1 | (r2 & (r1 >> 63)));
}
static inline uint32_t cqsf_f16_f32(struct sf_ctx *sf_ctx, uint16_t a) { return f16_to_f32(sf_ctx, (float16_t){a}).v; }
static inline uint32_t cqsf_bf16_f32(struct sf_ctx *sf_ctx, uint16_t a) { (void)sf_ctx; return (uint32_t)a << 16; }

#define CQSF_FPTOI(W, U, CVT32, CVT64, U64)                                                              \
static inline int8_t sfx_fptosi_##W##_to_i8(struct sf_ctx *sf_ctx, U a) { return (int8_t)CVT32; }          \
static inline int16_t sfx_fptosi_##W##_to_i16(struct sf_ctx *sf_ctx, U a) { return (int16_t)CVT32; }       \
static inline int32_t sfx_fptosi_##W##_to_i32(struct sf_ctx *sf_ctx, U a) { return CVT32; }                 \
static inline int64_t sfx_fptosi_##W##_to_i64(struct sf_ctx *sf_ctx, U a) { return CVT64; }                 \
static inline uint8_t sfx_fptoui_##W##_to_i8(struct sf_ctx *sf_ctx, U a) { return (uint8_t)CVT32; }        \
static inline uint16_t sfx_fptoui_##W##_to_i16(struct sf_ctx *sf_ctx, U a) { return (uint16_t)CVT32; }     \
static inline uint32_t sfx_fptoui_##W##_to_i32(struct sf_ctx *sf_ctx, U a) { return (uint32_t)CVT64; }     \
static inline uint64_t sfx_fptoui_##W##_to_i64(struct sf_ctx *sf_ctx, U a) { return U64; }

CQSF_FPTOI(f32, uint32_t, cqsf_c32_f32(sf_ctx, a), cqsf_c64_f32(sf_ctx, a), cqsf_u64_f32(sf_ctx, a))
CQSF_FPTOI(f64, uint64_t, cqsf_c32_f64(sf_ctx, a), cqsf_c64_f64(sf_ctx, a), cqsf_u64_f64(sf_ctx, a))
CQSF_FPTOI(f16, uint16_t, cqsf_c32_f32(sf_ctx, cqsf_f16_f32(sf_ctx, a)), cqsf_c64_f32(sf_ctx, cqsf_f16_f32(sf_ctx, a)),
           cqsf_u64_f32(sf_ctx, cqsf_f16_f32(sf_ctx, a)))
CQSF_FPTOI(bf16, uint16_t, cqsf_c32_f32(sf_ctx, cqsf_bf16_f32(sf_ctx, a)), cqsf_c64_f32(sf_ctx, cqsf_bf16_f32(sf_ctx, a)),
           cqsf_u64_f32(sf_ctx, cqsf_bf16_f32(sf_ctx, a)))

#endif
