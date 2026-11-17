/* cqsf_int.h: sitofp/uitofp from and fptosi/fptoui to the integer widths other than 1, 8, 16, 32, 64
 * (the INT_X widths of gen/gen_cqsf.py), on top of cqsf.h and cqsf_f80.h. CR §2:
 *
 *   iN -> fp, N <= 64     the source sign- or zero-extended to 64 bits, then the 64-bit conversion
 *                         (exact extension; codegen's own route). To bf16 through f32, two roundings.
 *   iN -> fp, 64 < N <= 128   compiler-rt (__floattisf, ...): IEEE is normative, one correct rounding
 *                         in the mode with IEEE flags; to bf16 through f32, two roundings.
 *   iN -> fp, N > 128     LLVM 19 ExpandLargeFpConvert's value: the magnitude rounded to nearest even
 *                         at f32/f64 precision (f80: at 113 bits into an fp128, then at 64 by
 *                         __trunctfxf2, two roundings) and packed with no range test, so the biased
 *                         exponent wraps into the sign bit (i200 2^150 -> f32 0x8a800000); the mode is
 *                         ignored. f16 and bf16: that f32 value, then f32 -> f16/bf16 in the mode.
 *                         uitofp to f80: the non-negative value rounded at 64 bits in the mode (the
 *                         expansion goes negative there, CR §2). Flags: those of the IEEE conversion
 *                         in the mode (f16/bf16: to f32, then of the second step).
 *   fp -> iN, N <= 64     cvtt at the narrowest legal width LLVM promotes to (signed N <= 32: c32,
 *                         else c64; unsigned N <= 31: c32, else c64); f80: fist16/32/64, signed the
 *                         narrowest >= N, unsigned the narrowest > N. Flags: those of that cvtt/fist.
 *   fp -> iN, 64 < N <= 128   the compiler-rt __fix[uns]{h,s,d,x}fti value at 128 bits, truncated.
 *   fp -> iN, N > 128     ExpandLargeFpConvert: |x| < 1 -> 0; exponent >= N saturates to the signed
 *                         N-bit extreme by sign (NaN included); else +-floor(|x|) mod 2^N (fptoui too).
 *                         f16: the expansion's own special case, the conversion to i32 extended.
 *   Flags for N > 64: INVALID for NaN, Inf, a non-canonical f80, or a value out of range at the
 *   conversion width (128, or N above 128), else INEXACT for a fraction (ruling 2026-10-27).
 *
 * A source wider than 64 bits arrives as a 256-bit two's complement value (struct cqsf_u256, four
 * limbs, sign- or zero-extended by the root). A result wider than 128 bits leaves as a 128-bit word:
 * the low 64 bits a magnitude m, bits 64-79 a left shift s, bit 80 the sign, bit 81 saturation; the
 * root forms (sat ? (neg ? MIN : MAX) : +-(m << s)) at N bits. Widths above 256 need more limbs. */
#ifndef CQSF_INT_H
#define CQSF_INT_H

#include "cqsf_f80.h"

typedef unsigned __int128 cqsf_u128;
struct cqsf_u256 { uint64_t w0, w1, w2, w3; };

static inline struct cqsf_u256 cqsf_u256_of128(cqsf_u128 a, bool sgn) {
    uint64_t hi = (uint64_t)(a >> 64), ext = (sgn && (hi >> 63)) ? ~(uint64_t)0 : 0;
    return (struct cqsf_u256){(uint64_t)a, hi, ext, ext};
}

/* The magnitude of x (signed: two's complement), normalized: msb position p, the 128 bits from the
 * msb down (hi with the msb at bit 63, lo) and a sticky bit for the rest. */
struct cqsf_mag { bool sign, zero; int_fast16_t p; uint64_t hi, lo; bool sticky; };
static inline struct cqsf_mag cqsf_mag256(struct cqsf_u256 x, bool sgn) {
    struct cqsf_mag m;
    m.sign = sgn && (x.w3 >> 63);
    if (m.sign) {
        x.w0 = ~x.w0; x.w1 = ~x.w1; x.w2 = ~x.w2; x.w3 = ~x.w3;
        x.w0 += 1;
        uint64_t c = (x.w0 == 0);
        x.w1 += c; c = c & (x.w1 == 0);
        x.w2 += c; c = c & (x.w2 == 0);
        x.w3 += c;
    }
    m.zero = !(x.w0 | x.w1 | x.w2 | x.w3);
    int_fast16_t p = 255;
    if (!x.w3) { x.w3 = x.w2; x.w2 = x.w1; x.w1 = x.w0; x.w0 = 0; p -= 64; }
    if (!x.w3) { x.w3 = x.w2; x.w2 = x.w1; x.w1 = 0; p -= 64; }
    if (!x.w3) { x.w3 = x.w2; x.w2 = 0; p -= 64; }
    uint_fast8_t s = x.w3 ? softfloat_countLeadingZeros64(x.w3) : 0;
    if (s) {
        x.w3 = (x.w3 << s) | (x.w2 >> (64 - s));
        x.w2 = (x.w2 << s) | (x.w1 >> (64 - s));
        x.w1 = (x.w1 << s) | (x.w0 >> (64 - s));
        x.w0 <<= s;
    }
    m.p = p - s; m.hi = x.w3; m.lo = x.w2; m.sticky = (x.w1 | x.w0) != 0;
    return m;
}
/* the top 63 bits, jammed: the value is sig63 * 2^(p - 62) */
static inline uint64_t cqsf_sig63(struct cqsf_mag m) { return (m.hi >> 1) | (uint64_t)(((m.hi & 1) | m.lo | m.sticky) != 0); }

/* IEEE: one correct rounding in the context's mode, IEEE flags. */
static inline uint16_t cqsf_mag_f16(struct sf_ctx *sf_ctx, struct cqsf_mag m) {
    if (m.zero) return 0;
    return softfloat_roundPackToF16(sf_ctx, m.sign, (int_fast16_t)(0x4C + m.p - 62), (uint_fast16_t)softfloat_shortShiftRightJam64(cqsf_sig63(m), 48)).v;
}
static inline uint32_t cqsf_mag_f32(struct sf_ctx *sf_ctx, struct cqsf_mag m) {
    if (m.zero) return 0;
    return softfloat_roundPackToF32(sf_ctx, m.sign, (int_fast16_t)(0xBC + m.p - 62), (uint_fast32_t)softfloat_shortShiftRightJam64(cqsf_sig63(m), 32)).v;
}
static inline uint64_t cqsf_mag_f64(struct sf_ctx *sf_ctx, struct cqsf_mag m) {
    if (m.zero) return 0;
    return softfloat_normRoundPackToF64(sf_ctx, m.sign, (int_fast16_t)(0x43C + m.p - 62), cqsf_sig63(m)).v;
}
static inline cqsf_x80 cqsf_mag_f80(struct sf_ctx *sf_ctx, struct cqsf_mag m) {
    if (m.zero) return (cqsf_x80){0, 0};
    return softfloat_roundPackToExtF80(sf_ctx, m.sign, (int_fast32_t)(0x3FFF + m.p), m.hi, m.lo | (uint64_t)m.sticky, 80);
}
static inline uint16_t cqsf_mag_bf16(struct sf_ctx *sf_ctx, struct cqsf_mag m) {
    return f32_to_bf16(sf_ctx, (float32_t){cqsf_mag_f32(sf_ctx, m)}).v;
}

/* ExpandLargeFpConvert (N > 128): round to nearest even at MW bits, pack with no range test. */
static inline uint64_t cqsf_xl_round(struct cqsf_mag m, int mw, int_fast16_t *e) {
    /* q = the top mw bits (mw <= 63 here), r the next bit, st the rest */
    uint64_t q = m.hi >> (64 - mw);
    bool r = (m.hi >> (63 - mw)) & 1;
    bool st = ((m.hi & ((UINT64_C(1) << (63 - mw)) - 1)) | m.lo | (uint64_t)m.sticky) != 0;
    *e = m.p;
    q += (uint64_t)(r && (st || (q & 1)));
    if (q >> mw) { q >>= 1; ++*e; }
    return q;
}
static inline uint32_t cqsf_xl_f32(struct cqsf_mag m) {
    if (m.zero) return 0;
    int_fast16_t e; uint64_t q = cqsf_xl_round(m, 24, &e);
    return (m.sign ? UINT32_C(0x80000000) : 0) | ((uint32_t)(e + 127) << 23) | ((uint32_t)q & UINT32_C(0x7FFFFF));
}
static inline uint64_t cqsf_xl_f64(struct cqsf_mag m) {
    if (m.zero) return 0;
    int_fast16_t e; uint64_t q = cqsf_xl_round(m, 53, &e);
    return (m.sign ? UINT64_C(0x8000000000000000) : 0) | ((uint64_t)(e + 1023) << 52) | (q & UINT64_C(0xFFFFFFFFFFFFF));
}
/* f80: the expansion builds an fp128 (nearest even at 113 bits) and truncates it to x87 (__trunctfxf2,
 * nearest even at 64 bits): two roundings. */
static inline cqsf_x80 cqsf_xl_f80(struct cqsf_mag m) {
    if (m.zero) return (cqsf_x80){0, 0};
    int_fast16_t e = m.p;
    uint64_t q = m.hi, lo = m.lo;
    /* 113 bits: hi and the top 49 bits of lo; the round bit is bit 14 of lo */
    bool r = (lo >> 14) & 1, st = ((lo & 0x3FFF) | (uint64_t)m.sticky) != 0;
    lo &= ~(uint64_t)0x7FFF;
    if (r && (st || ((lo >> 15) & 1))) {
        lo += 0x8000;
        if (!lo) { ++q; if (!q) { q = UINT64_C(0x8000000000000000); ++e; } }
    }
    /* 64 bits */
    r = lo >> 63; st = (lo << 1) != 0;
    if (r && (st || (q & 1))) { ++q; if (!q) { q = UINT64_C(0x8000000000000000); ++e; } }
    return (cqsf_x80){q, (uint16_t)((m.sign ? 0x8000 : 0) | (uint16_t)(e + 0x3FFF))};
}

/* iN -> fp for N > 64: x the 256-bit value, sgn sitofp, big N > 128. */
static inline uint16_t sfx_wi_to_f16(struct sf_ctx *sf_ctx, struct cqsf_u256 x, bool sgn, bool big) {
    struct cqsf_mag m = cqsf_mag256(x, sgn);
    if (!big) return cqsf_mag_f16(sf_ctx, m);
    (void)cqsf_mag_f32(sf_ctx, m);                                   /* the flags of the first step */
    return f32_to_f16(sf_ctx, (float32_t){cqsf_xl_f32(m)}).v;
}
static inline uint16_t sfx_wi_to_bf16(struct sf_ctx *sf_ctx, struct cqsf_u256 x, bool sgn, bool big) {
    struct cqsf_mag m = cqsf_mag256(x, sgn);
    if (!big) return cqsf_mag_bf16(sf_ctx, m);
    (void)cqsf_mag_f32(sf_ctx, m);
    return f32_to_bf16(sf_ctx, (float32_t){cqsf_xl_f32(m)}).v;
}
static inline uint32_t sfx_wi_to_f32(struct sf_ctx *sf_ctx, struct cqsf_u256 x, bool sgn, bool big) {
    struct cqsf_mag m = cqsf_mag256(x, sgn);
    uint32_t v = cqsf_mag_f32(sf_ctx, m);
    return big ? cqsf_xl_f32(m) : v;
}
static inline uint64_t sfx_wi_to_f64(struct sf_ctx *sf_ctx, struct cqsf_u256 x, bool sgn, bool big) {
    struct cqsf_mag m = cqsf_mag256(x, sgn);
    uint64_t v = cqsf_mag_f64(sf_ctx, m);
    return big ? cqsf_xl_f64(m) : v;
}
static inline cqsf_x80 sfx_wi_to_f80(struct sf_ctx *sf_ctx, struct cqsf_u256 x, bool sgn, bool big) {
    struct cqsf_mag m = cqsf_mag256(x, sgn);
    cqsf_x80 v = cqsf_mag_f80(sf_ctx, m);
    return (big && sgn) ? cqsf_xl_f80(m) : v;   /* uitofp above 128 bits: the IEEE value (CR §2) */
}

/* ---- fp -> int ------------------------------------------------------------------------------ */

/* A source as compiler-rt reads it: sign, unbiased exponent e (from the field, NaN and Inf included),
 * significand with the integer bit at bit mb (the implicit bit always set; f80: the stored one). */
struct cqsf_dec { bool sign, nan, inf, bad, zero; int_fast32_t e; uint64_t sig; int mb; };
static inline struct cqsf_dec cqsf_dec_f16(uint16_t a) {
    struct cqsf_dec d = {a >> 15, cqsf_isnan_f16(a), (a & 0x7FFF) == 0x7C00, false, !(a & 0x7FFF), (int_fast32_t)((a >> 10) & 0x1F) - 15,
                         (uint64_t)(a & 0x3FF) | 0x400, 10};
    return d;
}
static inline struct cqsf_dec cqsf_dec_f32(uint32_t a) {
    struct cqsf_dec d = {a >> 31, cqsf_isnan_f32(a), (a & 0x7FFFFFFF) == 0x7F800000, false, !(a & 0x7FFFFFFF), (int_fast32_t)((a >> 23) & 0xFF) - 127,
                         (uint64_t)(a & 0x7FFFFF) | 0x800000, 23};
    return d;
}
static inline struct cqsf_dec cqsf_dec_f64(uint64_t a) {
    struct cqsf_dec d = {a >> 63, cqsf_isnan_f64(a), (a & UINT64_C(0x7FFFFFFFFFFFFFFF)) == UINT64_C(0x7FF0000000000000), false,
                         !(a & UINT64_C(0x7FFFFFFFFFFFFFFF)),
                         (int_fast32_t)((a >> 52) & 0x7FF) - 1023, (a & UINT64_C(0xFFFFFFFFFFFFF)) | UINT64_C(0x10000000000000), 52};
    return d;
}
static inline struct cqsf_dec cqsf_dec_f80(cqsf_x80 a) {
    struct cqsf_dec d = {a.signExp >> 15, cqsf_isnan_f80(a), (a.signExp & 0x7FFF) == 0x7FFF && !(a.signif << 1),
                         cqsf_noncanon_f80(a), !(a.signExp & 0x7FFF) && !a.signif, (int_fast32_t)(a.signExp & 0x7FFF) - 16383, a.signif, 63};
    return d;
}
static inline struct cqsf_dec cqsf_dec_bf16(uint16_t a) { return cqsf_dec_f32((uint32_t)a << 16); }

/* |x| truncated, as a 128-bit value (0 <= e < 128) */
static inline cqsf_u128 cqsf_dec_trunc(struct cqsf_dec d) {
    return d.e < d.mb ? (cqsf_u128)(d.sig >> (d.mb - d.e)) : (cqsf_u128)d.sig << (d.e - d.mb);
}
/* compiler-rt __fix{h,s,d}fti / __fixuns{h,s,d}fti (fp_fixint_impl.inc, fp_fixuint_impl.inc) */
static inline cqsf_u128 cqsf_fixti(struct cqsf_dec d) {
    if (d.e < 0) return 0;
    if (d.e >= 128) return d.sign ? (cqsf_u128)1 << 127 : ~((cqsf_u128)1 << 127);
    cqsf_u128 r = cqsf_dec_trunc(d);
    return d.sign ? -r : r;
}
static inline cqsf_u128 cqsf_fixunsti(struct cqsf_dec d) {
    if (d.sign || d.e < 0) return 0;
    if (d.e >= 128) return ~(cqsf_u128)0;
    return cqsf_dec_trunc(d);
}
/* compiler-rt __fixxfti / __fixunsxfti (fixxfti.c, fixunsxfti.c): the stored significand, the x87 compare
 * a > 0 for the saturation sign (a NaN or a non-canonical encoding is unordered: MIN), e > 128 for the
 * unsigned saturation. */
static inline cqsf_u128 cqsf_fixxfti(struct cqsf_dec d) {
    if (d.e < 0) return 0;
    if (d.e >= 128) return (!d.sign && !d.nan && !d.bad) ? ~((cqsf_u128)1 << 127) : (cqsf_u128)1 << 127;
    cqsf_u128 r = cqsf_dec_trunc(d);
    return d.sign ? -r : r;
}
static inline cqsf_u128 cqsf_fixunsxfti(struct cqsf_dec d) {
    if (d.e < 0 || d.sign) return 0;
    if (d.e > 128) return ~(cqsf_u128)0;
    return d.e == 128 ? (cqsf_u128)d.sig << 65 : cqsf_dec_trunc(d);
}

/* The flags of a conversion to a W-bit integer, W > 64 (CR §2 row, ruling 2026-10-27). */
static inline void cqsf_fptoi_wflags(struct sf_ctx *sf_ctx, struct cqsf_dec d, int w, bool sgn) {
    if (d.nan || d.inf || d.bad) { softfloat_raiseFlags(softfloat_flag_invalid); return; }
    bool inv;
    if (d.e < 0) inv = false;                              /* |x| < 1: truncates to 0 */
    /* w > 64 > mb: at e = w - 1 every significand bit is an integer bit; only -2^(w-1) is in range */
    else if (sgn) inv = d.e > w - 1 || (d.e == w - 1 && !(d.sign && d.sig == (UINT64_C(1) << d.mb)));
    else inv = d.sign || d.e >= w;
    if (inv) { softfloat_raiseFlags(softfloat_flag_invalid); return; }
    bool frac;
    if (d.e < 0) frac = !d.zero;
    else frac = d.e < d.mb && (d.sig & ((UINT64_C(1) << (d.mb - d.e)) - 1));
    if (frac) softfloat_raiseFlags(softfloat_flag_inexact);
}

/* ExpandLargeFpConvert, fp -> iN for N > 128: the packed word (see the header). */
static inline cqsf_u128 cqsf_xl_fptoi(struct cqsf_dec d, int n) {
    uint64_t m = 0, s = 0, sat = 0;
    if (d.e >= n) sat = 1;
    else if (d.e >= 0) {
        if (d.e < d.mb) m = d.sig >> (d.mb - d.e);
        else { m = d.sig; s = (uint64_t)(d.e - d.mb); }
    }
    return (cqsf_u128)m | ((cqsf_u128)(s | ((uint64_t)d.sign << 16) | (sat << 17)) << 64);
}

/* The operations the roots call. N <= 64: the int64 the root truncates to N bits. */
static inline int64_t cqsf_fptoi_n32(struct sf_ctx *sf_ctx, uint32_t a, int n, bool sgn) {
    return (sgn ? n <= 32 : n <= 31) ? (int64_t)cqsf_c32_f32(sf_ctx, a) : cqsf_c64_f32(sf_ctx, a);
}
static inline int64_t sfx_fptoi_n_f16(struct sf_ctx *sf_ctx, uint16_t a, int n, bool sgn) { return cqsf_fptoi_n32(sf_ctx, cqsf_f16_f32(sf_ctx, a), n, sgn); }
static inline int64_t sfx_fptoi_n_bf16(struct sf_ctx *sf_ctx, uint16_t a, int n, bool sgn) { return cqsf_fptoi_n32(sf_ctx, cqsf_bf16_f32(sf_ctx, a), n, sgn); }
static inline int64_t sfx_fptoi_n_f32(struct sf_ctx *sf_ctx, uint32_t a, int n, bool sgn) { return cqsf_fptoi_n32(sf_ctx, a, n, sgn); }
static inline int64_t sfx_fptoi_n_f64(struct sf_ctx *sf_ctx, uint64_t a, int n, bool sgn) {
    return (sgn ? n <= 32 : n <= 31) ? (int64_t)cqsf_c32_f64(sf_ctx, a) : cqsf_c64_f64(sf_ctx, a);
}
static inline int64_t sfx_fptoi_n_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, int n, bool sgn) {
    if (sgn ? n <= 16 : n < 16) return cqsf_fistn(sf_ctx, a, 16);
    if (sgn ? n <= 32 : n < 32) return cqsf_fistn(sf_ctx, a, 32);
    return cqsf_fist64(sf_ctx, a);
}
/* 64 < N <= 128: the compiler-rt value at 128 bits; N > 128: the packed ExpandLargeFpConvert word. */
#define CQSF_FPTOI_W(W, U)                                                                               \
static inline cqsf_u128 sfx_fptoi_ti_##W(struct sf_ctx *sf_ctx, U a, bool sgn) {                          \
    struct cqsf_dec d = cqsf_dec_##W(a); cqsf_fptoi_wflags(sf_ctx, d, 128, sgn);                       \
    return sgn ? cqsf_fixti(d) : cqsf_fixunsti(d);                                                      \
}                                                                                                       \
static inline cqsf_u128 sfx_fptoi_xl_##W(struct sf_ctx *sf_ctx, U a, int n, bool sgn) {                   \
    struct cqsf_dec d = cqsf_dec_##W(a); cqsf_fptoi_wflags(sf_ctx, d, n, sgn);                         \
    return cqsf_xl_fptoi(d, n);                                                                         \
}
CQSF_FPTOI_W(bf16, uint16_t) CQSF_FPTOI_W(f32, uint32_t) CQSF_FPTOI_W(f64, uint64_t)
static inline cqsf_u128 sfx_fptoi_ti_f16(struct sf_ctx *sf_ctx, uint16_t a, bool sgn) {
    struct cqsf_dec d = cqsf_dec_f16(a); cqsf_fptoi_wflags(sf_ctx, d, 128, sgn);
    return sgn ? cqsf_fixti(d) : cqsf_fixunsti(d);
}
/* f16 above 128 bits: ExpandLargeFpConvert converts a half to i32 (fptosi: c32; fptoui: x86's fptoui to
 * i32, trunc(c64)) and sign- or zero-extends it ("fp16's range is covered by i32"); flags of that cvtt. */
static inline cqsf_u128 sfx_fptoi_xl_f16(struct sf_ctx *sf_ctx, uint16_t a, int n, bool sgn) {
    (void)n;
    int64_t v = cqsf_fptoi_n32(sf_ctx, cqsf_f16_f32(sf_ctx, a), 32, sgn);
    if (!sgn) return (cqsf_u128)(uint32_t)v;
    int32_t w = (int32_t)v;
    return w < 0 ? (cqsf_u128)(uint64_t)-(int64_t)w | ((cqsf_u128)1 << 80) : (cqsf_u128)(uint64_t)w;
}
static inline cqsf_u128 sfx_fptoi_ti_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, bool sgn) {
    struct cqsf_dec d = cqsf_dec_f80(a); cqsf_fptoi_wflags(sf_ctx, d, 128, sgn);
    return sgn ? cqsf_fixxfti(d) : cqsf_fixunsxfti(d);
}
static inline cqsf_u128 sfx_fptoi_xl_f80(struct sf_ctx *sf_ctx, cqsf_x80 a, int n, bool sgn) {
    struct cqsf_dec d = cqsf_dec_f80(a); cqsf_fptoi_wflags(sf_ctx, d, n, sgn);
    d.sig |= UINT64_C(0x8000000000000000);   /* the expansion sets the integer bit as for an implicit one */
    return cqsf_xl_fptoi(d, n);
}

#endif
