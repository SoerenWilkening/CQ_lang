/* cqsf_f80.h: the f80 (x87 extended) templates on the patched SoftFloat; see cqsf.h.
 *
 * An f80 bit pattern is struct extFloat80M (64-bit significand with the explicit integer bit, 16-bit
 * sign and exponent). CR §2: a non-canonical encoding (an unnormal, a pseudo-NaN, a pseudo-Inf: a
 * nonzero exponent with the integer bit clear) is an invalid operand: an fp result is the real
 * indefinite 0xFFFF_C000000000000000 and a compare is unordered, each with INVALID; a pseudo-denormal
 * (exponent 0, integer bit set) reads as a denormal (SoftFloat already reads it so). */
#ifndef CQSF_F80_H
#define CQSF_F80_H

#include "cqsf.h"
#include <string.h>

typedef struct extFloat80M cqsf_x80;

static inline cqsf_x80 cqsf_bits_f80(long double x) {
    cqsf_x80 r; memcpy(&r.signif, &x, 8); memcpy(&r.signExp, (const char *)&x + 8, 2); return r;
}
static inline long double cqsf_from_f80(cqsf_x80 a) {
    long double x = 0; memcpy(&x, &a.signif, 8); memcpy((char *)&x + 8, &a.signExp, 2); return x;
}
static inline bool cqsf_noncanon_f80(cqsf_x80 a) { return (a.signExp & 0x7FFF) && !(a.signif >> 63); }
static inline bool cqsf_isnan_f80(cqsf_x80 a) { return ((a.signExp & 0x7FFF) == 0x7FFF) && (a.signif << 1); }
static inline bool cqsf_issnan_f80(cqsf_x80 a) {
    return cqsf_isnan_f80(a) && (a.signif >> 63) && !(a.signif & UINT64_C(0x4000000000000000));
}
/* A pseudo-denormal (exponent 0, integer bit set) reads as a denormal (CR §2, x87): the same value with
 * the exponent field 1, which SoftFloat reads correctly. */
static inline cqsf_x80 cqsf_canon_f80(cqsf_x80 a) {
    if (!(a.signExp & 0x7FFF) && (a.signif >> 63)) a.signExp |= 1;
    return a;
}
static inline bool cqsf_isnanx_f80(cqsf_x80 a) { return cqsf_isnan_f80(a) || cqsf_noncanon_f80(a); }
static inline cqsf_x80 cqsf_indef_f80(struct sf_ctx *sf_ctx) {
    softfloat_raiseFlags(softfloat_flag_invalid);
    return (cqsf_x80){UINT64_C(0xC000000000000000), 0xFFFF};
}

/* Two operands: a non-canonical one gives the real indefinite with INVALID; a NaN gives the first NaN
 * operand quieted (CR §2: also for f80, where x87 would pick the larger significand), INVALID for an sNaN. */
static inline bool cqsf_nan2_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b, cqsf_x80 *z) {
    if (cqsf_noncanon_f80(a) || cqsf_noncanon_f80(b)) { *z = cqsf_indef_f80(sf_ctx); return true; }
    if (!cqsf_isnan_f80(a) && !cqsf_isnan_f80(b)) return false;
    if (cqsf_issnan_f80(a) || cqsf_issnan_f80(b)) softfloat_raiseFlags(softfloat_flag_invalid);
    *z = cqsf_isnan_f80(a) ? a : b;
    z->signif |= UINT64_C(0xC000000000000000);
    return true;
}
#define CQSF_X80_BIN(OP, FN)                                                                             \
static inline cqsf_x80 sfx_##OP##_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) {                    \
    cqsf_x80 z;                                                                                         \
    if (cqsf_nan2_f80(sf_ctx, a, b, &z)) return z;                                                      \
    return FN(sf_ctx, cqsf_canon_f80(a), cqsf_canon_f80(b));                                            \
}
CQSF_X80_BIN(fadd, extF80_add)
CQSF_X80_BIN(fsub, extF80_sub)
CQSF_X80_BIN(fmul, extF80_mul)
CQSF_X80_BIN(fdiv, extF80_div)

static inline cqsf_x80 sfx_sqrt_f80(struct sf_ctx *sf_ctx, cqsf_x80 a) {
    if (cqsf_noncanon_f80(a)) return cqsf_indef_f80(sf_ctx);
    return extF80_sqrt(sf_ctx, cqsf_canon_f80(a));
}

/* frem = C fmod, as in cqsf.h: the IEEE remainder corrected by an exact addition of copysign(|b|, a). */
static inline cqsf_x80 sfx_frem_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) {
    cqsf_x80 r;
    if (cqsf_nan2_f80(sf_ctx, a, b, &r)) return r;
    a = cqsf_canon_f80(a); b = cqsf_canon_f80(b);
    r = extF80_rem(sf_ctx, a, b);
    if (cqsf_isnan_f80(r) || !(r.signif) || !((r.signExp ^ a.signExp) & 0x8000)) return r;
    cqsf_x80 y = {b.signif, (uint16_t)((b.signExp & 0x7FFF) | (a.signExp & 0x8000))};
    return extF80_add(sf_ctx, r, y);
}

/* fma at f80: SoftFloat has no extF80_mulAdd. One rounding of the exact a*b + c, in SoftFloat's style:
 * the 128-bit product of the normalized significands (softfloat_mul64To128), c aligned to it in a 192-bit
 * frame with a sticky jam, the sum or difference (exact: when the two cancel, c is shifted by at most one
 * bit and every bit of both stays in the frame), normalized, and one softfloat_roundPackToExtF80 at
 * precision 80 in the context's mode with its flags. An exact zero sum is +0, -0 in round-down (IEEE).
 * Operands are canonical and not NaN (sfx_fma_f80 handles the rest by the CR §2 rows). */
struct cqsf_u192 { uint64_t w2, w1, w0; };
static inline struct cqsf_u192 cqsf_srj192(struct cqsf_u192 a, uint_fast32_t dist) {
    uint64_t st = 0;
    if (dist > 192) dist = 192;
    if (dist >= 64) { st |= a.w0; a.w0 = a.w1; a.w1 = a.w2; a.w2 = 0; dist -= 64; }
    if (dist >= 64) { st |= a.w0; a.w0 = a.w1; a.w1 = 0; dist -= 64; }
    if (dist >= 64) { st |= a.w0; a.w0 = 0; dist -= 64; }
    if (dist) {
        st |= a.w0 << (64 - dist);
        a.w0 = (a.w0 >> dist) | (a.w1 << (64 - dist));
        a.w1 = (a.w1 >> dist) | (a.w2 << (64 - dist));
        a.w2 >>= dist;
    }
    a.w0 |= (uint64_t)(st != 0);
    return a;
}
static inline cqsf_x80 cqsf_extF80_mulAdd(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b, cqsf_x80 c) {
    bool signA = a.signExp >> 15, signB = b.signExp >> 15, signC = c.signExp >> 15, signP = signA ^ signB;
    int_fast32_t expA = a.signExp & 0x7FFF, expB = b.signExp & 0x7FFF, expC = c.signExp & 0x7FFF;
    uint64_t sigA = a.signif, sigB = b.signif, sigC = c.signif;
    bool zeroA = !expA && !sigA, zeroB = !expB && !sigB, zeroC = !expC && !sigC;
    if (expA == 0x7FFF || expB == 0x7FFF) {                    /* an infinite product */
        if (zeroA || zeroB || (expC == 0x7FFF && signC != signP)) return cqsf_indef_f80(sf_ctx);
        return (cqsf_x80){UINT64_C(0x8000000000000000), (uint16_t)(((unsigned)signP << 15) | 0x7FFF)};
    }
    if (expC == 0x7FFF) return c;
    if (zeroA || zeroB) {                                      /* a zero product: c, or the sum of zeros */
        if (!zeroC) return c;
        bool s = (signP == signC) ? signP : (sf_ctx->roundingMode == softfloat_round_min);
        return (cqsf_x80){0, (uint16_t)((unsigned)s << 15)};
    }
    if (!expA) expA = 1;
    if (!(sigA >> 63)) { uint_fast8_t s = softfloat_countLeadingZeros64(sigA); expA -= s; sigA <<= s; }
    if (!expB) expB = 1;
    if (!(sigB >> 63)) { uint_fast8_t s = softfloat_countLeadingZeros64(sigB); expB -= s; sigB <<= s; }
    int_fast32_t expP = expA + expB - 0x3FFE;
    struct uint128 p = softfloat_mul64To128(sigA, sigB);
    if (!(p.v64 >> 63)) { --expP; p = softfloat_shortShiftLeft128(p.v64, p.v0, 1); }
    if (zeroC) return softfloat_roundPackToExtF80(sf_ctx, signP, expP, p.v64, p.v0, 80);
    if (!expC) expC = 1;
    if (!(sigC >> 63)) { uint_fast8_t s = softfloat_countLeadingZeros64(sigC); expC -= s; sigC <<= s; }
    /* the frame: the msb at bit 191 has the exponent expZ, as SoftFloat's sig with the msb at bit 63 */
    struct cqsf_u192 P = {p.v64, p.v0, 0}, C = {sigC, 0, 0}, x, y;
    int_fast32_t expDiff = expP - expC, expZ;
    bool signZ;
    if (expDiff >= 0) { x = P; y = cqsf_srj192(C, (uint_fast32_t)expDiff); expZ = expP; signZ = signP; }
    else { x = C; y = cqsf_srj192(P, (uint_fast32_t)-expDiff); expZ = expC; signZ = signC; }
    struct cqsf_u192 z;
    if (signP == signC) {
        z.w0 = x.w0 + y.w0;
        uint64_t c0 = z.w0 < x.w0;
        z.w1 = x.w1 + y.w1 + c0;
        uint64_t c1 = (z.w1 < x.w1) | (c0 & (z.w1 == x.w1));
        z.w2 = x.w2 + y.w2 + c1;
        uint64_t c2 = (z.w2 < x.w2) | (c1 & (z.w2 == x.w2));
        if (c2) {
            z.w0 = (z.w0 >> 1) | (z.w1 << 63) | (z.w0 & 1);
            z.w1 = (z.w1 >> 1) | (z.w2 << 63);
            z.w2 = (z.w2 >> 1) | UINT64_C(0x8000000000000000);
            ++expZ;
        }
    } else {
        z.w0 = x.w0 - y.w0;
        uint64_t b0 = x.w0 < y.w0;
        z.w1 = x.w1 - y.w1 - b0;
        uint64_t b1 = (x.w1 < y.w1) | (b0 & (x.w1 == y.w1));
        z.w2 = x.w2 - y.w2 - b1;
        uint64_t b2 = (x.w2 < y.w2) | (b1 & (x.w2 == y.w2));
        if (b2) {                                              /* only with expDiff = 0: |c| > |a*b| */
            z.w0 = ~z.w0; z.w1 = ~z.w1; z.w2 = ~z.w2;
            z.w0 += 1;
            uint64_t k = (z.w0 == 0);
            z.w1 += k; k &= (z.w1 == 0);
            z.w2 += k;
            signZ = !signZ;
        }
        if (!(z.w2 | z.w1 | z.w0))
            return (cqsf_x80){0, (uint16_t)(sf_ctx->roundingMode == softfloat_round_min ? 0x8000 : 0)};
        if (!z.w2) { z.w2 = z.w1; z.w1 = z.w0; z.w0 = 0; expZ -= 64; }
        if (!z.w2) { z.w2 = z.w1; z.w1 = 0; expZ -= 64; }
        uint_fast8_t s = softfloat_countLeadingZeros64(z.w2);
        if (s) {
            z.w2 = (z.w2 << s) | (z.w1 >> (64 - s));
            z.w1 = (z.w1 << s) | (z.w0 >> (64 - s));
            z.w0 <<= s;
            expZ -= s;
        }
    }
    return softfloat_roundPackToExtF80(sf_ctx, signZ, expZ, z.w2, z.w1 | (uint64_t)(z.w0 != 0), 80);
}
/* The CR §2 rows: a non-canonical operand gives the real indefinite with INVALID; a NaN the first NaN
 * operand quieted, INVALID only for an sNaN (the rule of the other widths' fma); a pseudo-denormal reads
 * as a denormal. */
static inline cqsf_x80 sfx_fma_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b, cqsf_x80 c) {
    if (cqsf_noncanon_f80(a) || cqsf_noncanon_f80(b) || cqsf_noncanon_f80(c)) return cqsf_indef_f80(sf_ctx);
    if (cqsf_isnan_f80(a) || cqsf_isnan_f80(b) || cqsf_isnan_f80(c)) {
        if (cqsf_issnan_f80(a) || cqsf_issnan_f80(b) || cqsf_issnan_f80(c)) softfloat_raiseFlags(softfloat_flag_invalid);
        cqsf_x80 z = cqsf_isnan_f80(a) ? a : cqsf_isnan_f80(b) ? b : c;
        z.signif |= UINT64_C(0xC000000000000000);
        return z;
    }
    return cqsf_extF80_mulAdd(sf_ctx, cqsf_canon_f80(a), cqsf_canon_f80(b), cqsf_canon_f80(c));
}

static inline cqsf_x80 sfx_fmax_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) {
    /* a non-canonical operand reads as a NaN (it compares unordered, with INVALID) */
    if (cqsf_issnan_f80(a) || cqsf_issnan_f80(b) || cqsf_noncanon_f80(a) || cqsf_noncanon_f80(b))
        softfloat_raiseFlags(softfloat_flag_invalid);
    if (cqsf_isnanx_f80(a)) return b;
    if (cqsf_isnanx_f80(b)) return a;
    return extF80_lt_quiet(sf_ctx, cqsf_canon_f80(a), cqsf_canon_f80(b)) ? b : a;   /* the operand itself */
}
static inline cqsf_x80 sfx_fmin_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) {
    /* a non-canonical operand reads as a NaN (it compares unordered, with INVALID) */
    if (cqsf_issnan_f80(a) || cqsf_issnan_f80(b) || cqsf_noncanon_f80(a) || cqsf_noncanon_f80(b))
        softfloat_raiseFlags(softfloat_flag_invalid);
    if (cqsf_isnanx_f80(a)) return b;
    if (cqsf_isnanx_f80(b)) return a;
    return extF80_lt_quiet(sf_ctx, cqsf_canon_f80(b), cqsf_canon_f80(a)) ? b : a;   /* the operand itself */
}

#define CQSF_X80_RND(OP, MODE, EXACT)                                                                   \
static inline cqsf_x80 sfx_##OP##_f80(struct sf_ctx *sf_ctx, cqsf_x80 a) {                                 \
    if (cqsf_noncanon_f80(a)) return cqsf_indef_f80(sf_ctx);                                                 \
    return extF80_roundToInt(sf_ctx, cqsf_canon_f80(a), MODE, EXACT);                                                        \
}
CQSF_X80_RND(floor, softfloat_round_min, false)
CQSF_X80_RND(ceil, softfloat_round_max, false)
CQSF_X80_RND(trunc, softfloat_round_minMag, false)
CQSF_X80_RND(round, softfloat_round_near_maxMag, false)
CQSF_X80_RND(rint, sf_ctx->roundingMode, true)

/* Compares: a non-canonical operand is unordered with INVALID (both kinds). */
#define CQSF_X80_CMP(K, OP, FN)                                                                          \
static inline bool sfx_cmp##K##_##OP##_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) {                \
    if (cqsf_noncanon_f80(a) || cqsf_noncanon_f80(b)) { softfloat_raiseFlags(softfloat_flag_invalid); return false; } \
    return FN(sf_ctx, cqsf_canon_f80(a), cqsf_canon_f80(b));                                                 \
}
CQSF_X80_CMP(q, eq, extF80_eq) CQSF_X80_CMP(q, lt, extF80_lt_quiet) CQSF_X80_CMP(q, le, extF80_le_quiet)
CQSF_X80_CMP(s, eq, extF80_eq_signaling) CQSF_X80_CMP(s, lt, extF80_lt) CQSF_X80_CMP(s, le, extF80_le)

/* ord/uno read a non-canonical operand as a NaN. */
#define CQSF_X80_PREDS(K)                                                                                \
static inline bool sfx_fcmp##K##_oeq_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) { return sfx_cmp##K##_eq_f80(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_ogt_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) { return sfx_cmp##K##_lt_f80(sf_ctx, b, a); } \
static inline bool sfx_fcmp##K##_oge_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) { return sfx_cmp##K##_le_f80(sf_ctx, b, a); } \
static inline bool sfx_fcmp##K##_olt_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) { return sfx_cmp##K##_lt_f80(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_ole_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) { return sfx_cmp##K##_le_f80(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_one_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) {                 \
    bool l = sfx_cmp##K##_lt_f80(sf_ctx, a, b); return sfx_cmp##K##_lt_f80(sf_ctx, b, a) || l; }                 \
static inline bool sfx_fcmp##K##_ord_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) {                 \
    (void)sfx_cmp##K##_eq_f80(sf_ctx, a, b); return !cqsf_isnanx_f80(a) && !cqsf_isnanx_f80(b); }           \
static inline bool sfx_fcmp##K##_uno_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) { return !sfx_fcmp##K##_ord_f80(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_ueq_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) {                 \
    bool e = sfx_cmp##K##_eq_f80(sf_ctx, a, b); return e || cqsf_isnanx_f80(a) || cqsf_isnanx_f80(b); }     \
static inline bool sfx_fcmp##K##_ugt_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) { return !sfx_cmp##K##_le_f80(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_uge_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) { return !sfx_cmp##K##_lt_f80(sf_ctx, a, b); } \
static inline bool sfx_fcmp##K##_ult_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) { return !sfx_cmp##K##_le_f80(sf_ctx, b, a); } \
static inline bool sfx_fcmp##K##_ule_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) { return !sfx_cmp##K##_lt_f80(sf_ctx, b, a); } \
static inline bool sfx_fcmp##K##_une_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, cqsf_x80 b) { return !sfx_cmp##K##_eq_f80(sf_ctx, a, b); }
CQSF_X80_PREDS(q)
CQSF_X80_PREDS(s)

/* is_fpclass on f80 (CR §2): a pseudo-denormal is subnormal, a non-canonical encoding a quiet NaN. */
static inline bool sfx_is_fpclass_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, uint32_t mask) {
    (void)sf_ctx;
    unsigned e = a.signExp & 0x7FFF; bool neg = a.signExp >> 15; unsigned bit;
    if (cqsf_noncanon_f80(a)) bit = 1u;
    else if (e == 0x7FFF) bit = (a.signif << 1) ? (((a.signif >> 62) & 1) ? 1u : 0u) : (neg ? 2u : 9u);
    else if (e) bit = neg ? 3u : 8u;
    else bit = a.signif ? (neg ? 4u : 7u) : (neg ? 5u : 6u);
    return (mask >> bit) & 1u;
}

/* Conversions. */
static inline cqsf_x80 sfx_fpext_f16_to_f80(struct sf_ctx *sf_ctx, uint16_t a) { return f16_to_extF80(sf_ctx, (float16_t){a}); }
static inline cqsf_x80 sfx_fpext_f32_to_f80(struct sf_ctx *sf_ctx, uint32_t a) { return f32_to_extF80(sf_ctx, (float32_t){a}); }
static inline cqsf_x80 sfx_fpext_f64_to_f80(struct sf_ctx *sf_ctx, uint64_t a) { return f64_to_extF80(sf_ctx, (float64_t){a}); }
static inline uint16_t sfx_fptrunc_f80_to_f16(struct sf_ctx *sf_ctx, cqsf_x80 a) {
    if (cqsf_noncanon_f80(a)) { softfloat_raiseFlags(softfloat_flag_invalid); return 0xFE00; }
    return extF80_to_f16(sf_ctx, cqsf_canon_f80(a)).v;
}
static inline uint32_t sfx_fptrunc_f80_to_f32(struct sf_ctx *sf_ctx, cqsf_x80 a) {
    if (cqsf_noncanon_f80(a)) { softfloat_raiseFlags(softfloat_flag_invalid); return UINT32_C(0xFFC00000); }
    return extF80_to_f32(sf_ctx, cqsf_canon_f80(a)).v;
}
static inline uint64_t sfx_fptrunc_f80_to_f64(struct sf_ctx *sf_ctx, cqsf_x80 a) {
    if (cqsf_noncanon_f80(a)) { softfloat_raiseFlags(softfloat_flag_invalid); return UINT64_C(0xFFF8000000000000); }
    return extF80_to_f64(sf_ctx, cqsf_canon_f80(a)).v;
}
static inline cqsf_x80 sfx_si_to_f80(struct sf_ctx *sf_ctx, int64_t x) { return i64_to_extF80(sf_ctx, x); }
static inline cqsf_x80 sfx_ui_to_f80(struct sf_ctx *sf_ctx, uint64_t x) { return ui64_to_extF80(sf_ctx, x); }

/* x87 fist with the indefinite INT_MIN of its width (CR §2): s8 = trunc(fist16), s16 = fist16,
 * s32 = fist32, s64 = fist64; u8 = trunc(fist16), u16 = trunc(fist32), u32 = trunc(fist64),
 * u64 = x < 2^63 ? fist64(x) : fist64(x - 2^63) ^ 2^63. Out of range: INVALID alone. */
static inline int64_t cqsf_fist64(struct sf_ctx *sf_ctx, cqsf_x80 a) {
    if (cqsf_noncanon_f80(a)) { softfloat_raiseFlags(softfloat_flag_invalid); return INT64_MIN; }
    return (int64_t)extF80_to_i64_r_minMag(sf_ctx, cqsf_canon_f80(a), true);
}
static inline int64_t cqsf_fistn(struct sf_ctx *sf_ctx, cqsf_x80 a, int bits) {
    struct sf_ctx t = {sf_ctx->roundingMode, 0};
    int64_t v = cqsf_fist64(&t, a), lo = -((int64_t)1 << (bits - 1)), hi = ((int64_t)1 << (bits - 1)) - 1;
    if ((t.exceptionFlags & softfloat_flag_invalid) || v < lo || v > hi) {
        softfloat_raiseFlags(softfloat_flag_invalid);
        return lo;
    }
    softfloat_raiseFlags(t.exceptionFlags);
    return v;
}
static inline int8_t sfx_fptosi_f80_to_i8(struct sf_ctx *sf_ctx, cqsf_x80 a) { return (int8_t)cqsf_fistn(sf_ctx, a, 16); }
static inline int16_t sfx_fptosi_f80_to_i16(struct sf_ctx *sf_ctx, cqsf_x80 a) { return (int16_t)cqsf_fistn(sf_ctx, a, 16); }
static inline int32_t sfx_fptosi_f80_to_i32(struct sf_ctx *sf_ctx, cqsf_x80 a) { return (int32_t)cqsf_fistn(sf_ctx, a, 32); }
static inline int64_t sfx_fptosi_f80_to_i64(struct sf_ctx *sf_ctx, cqsf_x80 a) { return cqsf_fist64(sf_ctx, a); }
static inline uint8_t sfx_fptoui_f80_to_i8(struct sf_ctx *sf_ctx, cqsf_x80 a) { return (uint8_t)cqsf_fistn(sf_ctx, a, 16); }
static inline uint16_t sfx_fptoui_f80_to_i16(struct sf_ctx *sf_ctx, cqsf_x80 a) { return (uint16_t)cqsf_fistn(sf_ctx, a, 32); }
static inline uint32_t sfx_fptoui_f80_to_i32(struct sf_ctx *sf_ctx, cqsf_x80 a) { return (uint32_t)cqsf_fist64(sf_ctx, a); }
static inline uint64_t sfx_fptoui_f80_to_i64(struct sf_ctx *sf_ctx, cqsf_x80 a) {
    cqsf_x80 two63 = {UINT64_C(0x8000000000000000), 0x403E};
    if (sfx_cmpq_lt_f80(sf_ctx, a, two63)) return (uint64_t)cqsf_fist64(sf_ctx, a);
    return (uint64_t)cqsf_fist64(sf_ctx, sfx_fsub_f80(sf_ctx, a, two63)) ^ UINT64_C(0x8000000000000000);
}

#endif
