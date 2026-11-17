/* selftest_int.c: the INT_X conversions (cq/cqsf_int.h; their roots are IR, cq/cqsf_roots_x.ll, called through
 * the native entries cqsft_*) against the host and CR §2, bit for bit, in the four modes, with the flags.
 * Build and run: softfloat/test/run_selftest.sh int.
 *
 * References (each named in the report):
 *   values in round-to-nearest: the host's -O1 conversion (host_int.c: cvtt/fist, compiler-rt, the
 *     ExpandLargeFpConvert expansion), except where CR §2 overrides it (uitofp above 128 bits to f80) or the
 *     host has none (iN <-> f16, 64 < N <= 128: no __floattihf/__fixhfti in LLVM 19's compiler-rt for x86
 *     macOS; the reference is then ref_round, or compiler-rt's fp_fixint formula written out here);
 *   IEEE values and flags in a mode (iN -> fp; CR §2 makes IEEE normative where compiler-rt computes, and
 *     the expansion's flags IEEE in the mode): ref_round, the magnitude rounded here by integer arithmetic
 *     (f16/bf16 second steps: the host's F16C conversion in the mode, ref_bf16 for bf16);
 *   fp -> iN flags: N <= 64 the host's strict conversion to _BitInt(N) (FENV_ACCESS); N > 64 the CR §2 row
 *     evaluated in long double. */
#pragma STDC FENV_ACCESS ON
#include <fenv.h>
#include <inttypes.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cqsf_roots.h"

typedef unsigned _BitInt(256) u256;
typedef uint64_t u64;
#define FE_ALL (FE_INVALID | FE_DIVBYZERO | FE_OVERFLOW | FE_UNDERFLOW | FE_INEXACT)
static const int MODES[4] = {FE_TONEAREST, FE_DOWNWARD, FE_UPWARD, FE_TOWARDZERO};
static void hbegin(int m) { fesetround(m); feclearexcept(FE_ALL_EXCEPT); }
static unsigned hend(void) { unsigned f = (unsigned)fetestexcept(FE_ALL); fesetround(FE_TONEAREST); return f; }

enum { TF16, TBF16, TF32, TF64, TF80 };
static const int TP[5] = {11, 8, 24, 53, 64}, TEMAX[5] = {15, 127, 127, 1023, 16383}, TSZ[5] = {2, 2, 4, 8, 10};

static u64 rng = 0x452821E638D01377u;
static u64 rnd(void) { rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17; return rng; }
static u256 mask(int n) { return n >= 256 ? ~(u256)0 : (((u256)1 << n) - 1); }
static int msb256(u256 x) { int p = -1; for (int k = 3; k >= 0; k--) { u64 w = (u64)(x >> (64 * k)); if (w) { p = 64 * k + 63 - __builtin_clzll(w); break; } } return p; }

/* ---- bookkeeping ---- */
typedef struct { const char *op; long n, badv, badf, nhost, badhost, over; const char *note; } Stat;
static Stat st[512]; static int nst;
static Stat *so(const char *op) { for (int i = 0; i < nst; i++) if (!strcmp(st[i].op, op)) return &st[i]; st[nst].op = strdup(op); return &st[nst++]; }
static void chk(const char *op, int m, u256 in, u256 lv, u256 rv, unsigned lf, unsigned rf, int cmpf) {
    Stat *s = so(op); s->n++;
    int bv = lv != rv, bf = cmpf && lf != rf;
    s->badv += bv; s->badf += bf;
    if ((bv || bf) && s->badv + s->badf <= 3)
        printf("MISMATCH %-26s mode %4d in %#" PRIx64 ":%016" PRIx64 ":%016" PRIx64 ": lib %#" PRIx64 ":%016" PRIx64 " f%02x ref %#" PRIx64 ":%016" PRIx64 " f%02x\n",
               op, m, (u64)(in >> 128), (u64)(in >> 64), (u64)in, (u64)(lv >> 64), (u64)lv, lf, (u64)(rv >> 64), (u64)rv, rf);
}

/* ---- the independent IEEE rounding of an integer magnitude ---- */
typedef struct { long double v; unsigned f; } RR;
static RR ref_round(u256 M, int neg, int P, int emax, int m) {
    RR r = {0.0L, 0};
    if (!M) return r;
    int p = msb256(M), sh = p >= P ? p - P + 1 : 0;
    u256 q = M >> sh, rem = sh ? (M & mask(sh)) : 0, half = sh ? (u256)1 << (sh - 1) : 0;
    int up = 0;
    if (rem) {
        r.f = FE_INEXACT;
        if (m == FE_TONEAREST) up = rem > half || (rem == half && (q & 1));
        else if (m == FE_UPWARD) up = !neg;
        else if (m == FE_DOWNWARD) up = neg;
    }
    q += (u256)up;
    if (q >> P) { q >>= 1; sh++; }
    if (msb256(q) + sh > emax) {
        r.f = FE_OVERFLOW | FE_INEXACT;
        int inf = m == FE_TONEAREST || (m == FE_UPWARD && !neg) || (m == FE_DOWNWARD && neg);
        u64 mx = P == 64 ? ~(u64)0 : ((u64)1 << P) - 1;
        r.v = inf ? (long double)INFINITY : ldexpl((long double)mx, emax - P + 1);
    } else r.v = ldexpl((long double)(u64)q, sh);
    if (neg) r.v = -r.v;
    return r;
}
/* M rounded to nearest even at P significant bits, as an integer */
static u256 rne_int(u256 M, int P) {
    int p = msb256(M);
    if (p < P) return M;
    int sh = p - P + 1;
    u256 q = M >> sh, rem = M & mask(sh), half = (u256)1 << (sh - 1);
    q += (u256)(rem > half || (rem == half && (q & 1)));
    return q << sh;
}
static u256 ld_bits(long double v, int t) {
    u256 b = 0;
    if (t == TF16) { _Float16 h = (_Float16)(float)v; memcpy(&b, &h, 2); }
    else if (t == TBF16) { float f = (float)v; uint32_t u; memcpy(&u, &f, 4); b = u >> 16; }
    else if (t == TF32) { float f = (float)v; memcpy(&b, &f, 4); }
    else if (t == TF64) { double d = (double)v; memcpy(&b, &d, 8); }
    else memcpy(&b, &v, 10);
    return b;
}
/* f32 bits -> bf16 in a mode, IEEE flags (tininess after rounding); a NaN quieted with its high payload */
static uint16_t ref_bf16(uint32_t b, int m, unsigned *fl) {
    unsigned sg = b >> 31, e = (b >> 23) & 0xFF; uint32_t f = b & 0x7FFFFF, mag = b & 0x7FFFFFFF;
    if (e == 0xFF) { if (f && !(f & 0x400000)) *fl |= FE_INVALID; return (uint16_t)((b >> 16) | (f ? 0x40 : 0)); }
    uint32_t q = mag >> 16, rem = mag & 0xFFFF; int up = 0;
    if (rem) {
        *fl |= FE_INEXACT;
        if (m == FE_TONEAREST) up = rem > 0x8000 || (rem == 0x8000 && (q & 1));
        else if (m == FE_UPWARD) up = !sg; else if (m == FE_DOWNWARD) up = sg;
        if (e == 0) {   /* tiny unless the unbounded rounding at 8 bits reaches 2^-126 */
            int tiny = 1;
            if (f >> 22) {
                uint32_t q2 = f >> 15, r2 = f & 0x7FFF; int u2 = 0;
                if (m == FE_TONEAREST) u2 = r2 > 0x4000 || (r2 == 0x4000 && (q2 & 1));
                else if (m == FE_UPWARD) u2 = !sg && r2; else if (m == FE_DOWNWARD) u2 = sg && r2;
                tiny = q2 + (uint32_t)u2 < 0x100;
            }
            if (tiny) *fl |= FE_UNDERFLOW;
        }
    }
    q += (uint32_t)up;
    if (q >= 0x7F80) {
        *fl |= FE_OVERFLOW | FE_INEXACT;
        int inf = m == FE_TONEAREST || (m == FE_UPWARD && !sg) || (m == FE_DOWNWARD && sg);
        q = inf ? 0x7F80 : 0x7F7F;
    }
    return (uint16_t)((sg << 15) | q);
}

/* ---- the conversions ---- */
typedef int (*HostFn)(const void *, void *);
typedef void (*LibFn)(const void *, uint32_t, void *);
typedef struct { int n, sg, t; const char *name; LibFn plain, m, x; HostFn host; } ITE;
typedef struct { int n, sg, t; const char *name; LibFn plain, x; HostFn host; unsigned (*sflags)(const void *); } FTE;
#define DH(N, TN) int hv_sitofp_i##N##_to_##TN(const void *, void *); int hv_uitofp_i##N##_to_##TN(const void *, void *); \
    int hv_fptosi_##TN##_to_i##N(const void *, void *); int hv_fptoui_##TN##_to_i##N(const void *, void *);
#define DHA(N) DH(N, f16) DH(N, bf16) DH(N, f32) DH(N, f64) DH(N, f80)
DHA(7) DHA(24) DHA(48) DHA(100) DHA(128) DHA(200)

/* the host's strict fp -> _BitInt(N) flags, N <= 64 (bf16: through the exact float, no strict bf16 op) */
#define SFL(N, T, TN, CV)                                                                                \
static unsigned sfs_##TN##_##N(const void *i) { T x; memcpy(&x, i, sizeof x); hbegin(FE_TONEAREST); volatile _BitInt(N) r = (_BitInt(N))CV; (void)r; return hend(); } \
static unsigned sfu_##TN##_##N(const void *i) { T x; memcpy(&x, i, sizeof x); hbegin(FE_TONEAREST); volatile unsigned _BitInt(N) r = (unsigned _BitInt(N))CV; (void)r; return hend(); }
static float bff(uint16_t b) { uint32_t u = (uint32_t)b << 16; float f; memcpy(&f, &u, 4); return f; }
#define SFLA(N) SFL(N, _Float16, f16, x) SFL(N, uint16_t, bf16, bff(x)) SFL(N, float, f32, x) SFL(N, double, f64, x) SFL(N, long double, f80, x)
SFLA(7) SFLA(24) SFLA(48) SFL(32, _Float16, f16, x)   /* f16 above 128 bits: the expansion converts to i32 */

#define IT2(N, T, TN) {N, 1, T, "sitofp_i" #N "_to_" #TN, cqsft_sitofp_i##N##_to_##TN, cqsft_sitofp_i##N##_to_##TN##_m, \
    cqsft_sitofp_i##N##_to_##TN##_x, hv_sitofp_i##N##_to_##TN}, {N, 0, T, "uitofp_i" #N "_to_" #TN, cqsft_uitofp_i##N##_to_##TN, \
    cqsft_uitofp_i##N##_to_##TN##_m, cqsft_uitofp_i##N##_to_##TN##_x, hv_uitofp_i##N##_to_##TN},
#define ITA(N) IT2(N, TF16, f16) IT2(N, TBF16, bf16) IT2(N, TF32, f32) IT2(N, TF64, f64) IT2(N, TF80, f80)
static const ITE its[] = {ITA(7) ITA(24) ITA(48) ITA(100) ITA(128) ITA(200)};
#define FT2(N, T, TN, SS, SU) {N, 1, T, "fptosi_" #TN "_to_i" #N, cqsft_fptosi_##TN##_to_i##N, cqsft_fptosi_##TN##_to_i##N##_x, \
    hv_fptosi_##TN##_to_i##N, SS}, {N, 0, T, "fptoui_" #TN "_to_i" #N, cqsft_fptoui_##TN##_to_i##N, cqsft_fptoui_##TN##_to_i##N##_x, \
    hv_fptoui_##TN##_to_i##N, SU},
#define FTN(N) FT2(N, TF16, f16, sfs_f16_##N, sfu_f16_##N) FT2(N, TBF16, bf16, sfs_bf16_##N, sfu_bf16_##N) \
    FT2(N, TF32, f32, sfs_f32_##N, sfu_f32_##N) FT2(N, TF64, f64, sfs_f64_##N, sfu_f64_##N) FT2(N, TF80, f80, sfs_f80_##N, sfu_f80_##N)
#define FTW(N) FT2(N, TF16, f16, 0, 0) FT2(N, TBF16, bf16, 0, 0) FT2(N, TF32, f32, 0, 0) FT2(N, TF64, f64, 0, 0) FT2(N, TF80, f80, 0, 0)
#define FTB(N) FT2(N, TF16, f16, sfs_f16_32, sfu_f16_32) FT2(N, TBF16, bf16, 0, 0) FT2(N, TF32, f32, 0, 0) FT2(N, TF64, f64, 0, 0) \
    FT2(N, TF80, f80, 0, 0)
static const FTE fts[] = {FTN(7) FTN(24) FTN(48) FTW(100) FTW(128) FTB(200)};

/* an N-bit input: specials, rounding ties and carries at each precision, random magnitudes */
static u256 int_in(int n, long t) {
    static const int P[] = {8, 11, 24, 53, 64};
    u256 mk = mask(n);
    switch (t) {
    case 0: return 0;
    case 1: return 1;
    case 2: return mk;                                  /* -1 / max unsigned */
    case 3: return (u256)1 << (n - 1);                  /* min signed */
    case 4: return mk >> 1;                             /* max signed */
    }
    u256 r = 0;
    for (int k = 0; k < 4; k++) r |= (u256)rnd() << (64 * k);
    int kind = (int)(rnd() % 6), p = P[rnd() % 5];
    int sh = n > p + 2 ? (int)(rnd() % (u64)(n - p - 1)) : 0;
    if (kind == 0) return r & mk;
    if (kind == 1) return (r >> (rnd() % 256)) & mk;
    if (kind == 2 && n > p + 1) return ((((u256)1 << p) | 1) << sh) & mk;                       /* a tie */
    if (kind == 3 && n > p + 1) return (((((u256)1 << p) | 1) << sh) | (sh ? 1 : 0)) & mk;     /* just above */
    if (kind == 4 && n > p) return ((((u256)1 << (p + 1)) - 1) << sh) & mk;                    /* a carry */
    return (~(r >> (rnd() % 256))) & mk;
}

static void run_itofp(const ITE *e) {
    unsigned char in[32], out[32], ho[32];
    char nm[64], nmr[64];
    snprintf(nmr, sizeof nmr, "%s_rm", e->name);
    for (long t = 0; t < 6000; t++) {
        u256 v = int_in(e->n, t);
        memset(in, 0, 32); memcpy(in, &v, 32);
        if (e->sg && e->n < 256 && ((v >> (e->n - 1)) & 1)) { u256 sx = v | ~mask(e->n); memcpy(in, &sx, 32); }
        int neg = e->sg && ((v >> (e->n - 1)) & 1);
        u256 M = neg ? ((~v + 1) & mask(e->n)) : v;
        if (neg && !M) M = (u256)1 << (e->n - 1);
        int big = e->n > 128;
        memset(ho, 0, 32);
        int hasho = e->host(in, ho);
        u256 hv = 0; memcpy(&hv, ho, (size_t)TSZ[e->t]);
        for (int mi = 0; mi < 4; mi++) {
            int m = MODES[mi];
            u256 rv; unsigned rf;
            if (e->t == TBF16 && !big) {               /* two roundings: iN -> f32, then -> bf16 */
                RR r1 = ref_round(M, neg, 24, 127, m); float f1 = (float)r1.v; uint32_t b1; memcpy(&b1, &f1, 4);
                unsigned f2 = 0; rv = ref_bf16(b1, m, &f2); rf = r1.f | f2;
            } else if (!big || (e->t == TF80 && !e->sg)) {
                RR r = ref_round(M, neg, TP[e->t], TEMAX[e->t], m); rv = ld_bits(r.v, e->t); rf = r.f;
            } else {                                   /* the expansion's value, IEEE flags in the mode */
                if (e->t == TF16 || e->t == TBF16) {
                    unsigned char h32[32] = {0};
                    for (unsigned k = 0; k < sizeof its / sizeof its[0]; k++)     /* the host's iN -> f32 */
                        if (its[k].n == e->n && its[k].sg == e->sg && its[k].t == TF32) its[k].host(in, h32);
                    uint32_t b1; memcpy(&b1, h32, 4);
                    rf = ref_round(M, neg, 24, 127, m).f;
                    if (e->t == TF16) { float f1; memcpy(&f1, &b1, 4); volatile float vf = f1; hbegin(m); volatile _Float16 h = (_Float16)vf; rf |= hend(); _Float16 hh = h; rv = 0; memcpy(&rv, &hh, 2); }
                    else { unsigned f2 = 0; rv = ref_bf16(b1, m, &f2); rf |= f2; }
                } else {
                    rf = ref_round(M, neg, TP[e->t], TEMAX[e->t], m).f;
                    /* f80: no host (fp128 libcalls); the expansion's two roundings, at 113 then 64 bits */
                    rv = e->t == TF80 ? ld_bits(ref_round(rne_int(M, 113), neg, 64, 16383, FE_TONEAREST).v, TF80) : hv;
                }
            }
            u256 lv = 0; uint32_t lf = 0;
            if (mi == 0) { memset(out, 0, 32); e->plain(in, 0, out); memcpy(&lv, out, (size_t)TSZ[e->t]); e->x(in, 0, &lf); chk(e->name, m, v, lv, rv, lf, rf, 1); }
            memset(out, 0, 32); e->m(in, (uint32_t)m, out); lv = 0; memcpy(&lv, out, (size_t)TSZ[e->t]); e->x(in, (uint32_t)m, &lf);
            chk(nmr, m, v, lv, rv, lf, rf, 1);
            if (mi == 0 && hasho) {                    /* the host's own value, bit for bit */
                Stat *s = so(e->name); s->nhost++;
                if (big && e->t == TF80 && !e->sg && ((v >> (e->n - 1)) & 1)) s->over++;   /* CR §2 overrides */
                else if (rv != hv) { s->badhost++; if (s->badhost <= 3) printf("HOST %s in %#" PRIx64 ": ref %#" PRIx64 " host %#" PRIx64 "\n", e->name, (u64)v, (u64)rv, (u64)hv); }
            }
        }
    }
    (void)nm;
}

/* ---- fp -> int ---- */
static u256 fp_in(int t, long i) {
    u256 b = 0;
    if (t == TF16 || t == TBF16) return (u256)(i & 0xFFFF);                  /* exhaustive */
    int pk[] = {6, 7, 15, 16, 23, 24, 31, 32, 47, 48, 63, 64, 99, 100, 127, 128, 199, 200};
    u64 r = rnd(); int neg = r & 1;
    long double v;
    switch ((r >> 1) % 6) {
    case 0: { int k = pk[rnd() % 18]; v = ldexpl(1.0L, k); int d = (int)(rnd() % 5); if (d == 1) v = nextafterl(v, 0); if (d == 2) v = nextafterl(v, INFINITY);
              if (d == 3) v += 0.5L; break; }
    case 1: v = ldexpl((long double)(rnd() | 1), (int)(rnd() % 220) - 66); break;
    case 2: v = ldexpl((long double)rnd(), -(int)(rnd() % 70)); break;
    case 3: { u64 sp[] = {0, 1}; (void)sp; v = (long double)(rnd() % 1000) / 8; break; }
    case 4: { u64 bits = rnd(); if (t == TF32) { uint32_t u = (uint32_t)bits; float f; memcpy(&f, &u, 4); memcpy(&b, &f, 4); return b; }
              if (t == TF64) { memcpy(&b, &bits, 8); return b; }
              b = (u256)bits | ((u256)(rnd() & 0xFFFF) << 64); return b; }          /* f80: any encoding */
    default: { static const u64 m80[] = {0, 1, 0x8000000000000000u, 0xC000000000000000u, 0x4000000000000000u, 0xFFFFFFFFFFFFFFFFu};
               static const unsigned e80[] = {0, 0x7FFF, 0x3FFF, 0x403E, 0x407F, 0x40C6, 0x40C7};
               if (t == TF80) { b = (u256)m80[rnd() % 6] | ((u256)(e80[rnd() % 7] | (neg ? 0x8000u : 0)) << 64); return b; }
               v = (rnd() & 1) ? (long double)INFINITY : (long double)NAN; break; }
    }
    if (neg) v = -v;
    if (t == TF32) { float f = (float)v; memcpy(&b, &f, 4); }
    else if (t == TF64) { double d = (double)v; memcpy(&b, &d, 8); }
    else memcpy(&b, &v, 10);
    return b;
}
static long double fp_val(u256 b, int t, int *nan, int *inf, int *bad) {
    *nan = *inf = *bad = 0;
    long double x;
    if (t == TF16) { _Float16 h; uint16_t u = (uint16_t)b; memcpy(&h, &u, 2); x = (long double)(float)h; }
    else if (t == TBF16) x = (long double)bff((uint16_t)b);
    else if (t == TF32) { float f; uint32_t u = (uint32_t)b; memcpy(&f, &u, 4); x = f; }
    else if (t == TF64) { double d; u64 u = (u64)b; memcpy(&d, &u, 8); x = d; }
    else { memcpy(&x, &b, 10); unsigned e = (unsigned)(b >> 64) & 0x7FFF; *bad = e && !((u64)b >> 63); }
    *nan = isnan(x); *inf = isinf(x);
    return x;
}
/* compiler-rt __fix[uns]hfti (fp_fixint_impl.inc) written out: the host has no half builtins */
static u256 ref_fixhfti(uint16_t a, int sg) {
    int e = ((a >> 10) & 31) - 15, neg = a >> 15; u64 sig = (u64)(a & 0x3FF) | 0x400;
    if (e < 0 || (!sg && neg)) return 0;
    unsigned __int128 r = e < 10 ? sig >> (10 - e) : (unsigned __int128)sig << (e - 10);
    return (u256)(sg && neg ? -r : r);
}
static void run_fptoi(const FTE *e) {
    unsigned char in[32], out[32], ho[32];
    long tot = (e->t == TF16 || e->t == TBF16) ? 65536 : 12000;
    char nmx[64]; snprintf(nmx, sizeof nmx, "%s (flags)", e->name);
    for (long i = 0; i < tot; i++) {
        u256 b = fp_in(e->t, i);
        memset(in, 0, 32); memcpy(in, &b, 16);
        int nan, inf, bad; long double x = fp_val(b, e->t, &nan, &inf, &bad);
        u256 mk = mask(e->n), rv = 0;
        memset(ho, 0, 32);
        if (e->host(in, ho)) memcpy(&rv, ho, 32);
        else if (e->t == TF16) rv = ref_fixhfti((uint16_t)b, e->sg);
        else {   /* f80 -> iN, N > 128: the CR §2 row on the fp128 extension (integer bit read as set) */
            int ex = (int)((unsigned)(b >> 64) & 0x7FFF) - 16383, ng = (int)((b >> 79) & 1);
            u256 sig = (u256)((u64)b | 0x8000000000000000u);
            if (ex < 0) rv = 0;
            else if (ex >= e->n) rv = ng ? (u256)1 << (e->n - 1) : mask(e->n - 1);
            else { u256 fl = ex >= 63 ? sig << (ex - 63) : sig >> (63 - ex); rv = ng ? -fl : fl; }
        }
        rv &= mk;
        unsigned rf;
        if (e->sflags) rf = e->sflags(in);
        else if (nan || inf || bad) rf = FE_INVALID;
        else {
            int w = e->n <= 128 ? 128 : e->n;
            long double tr = truncl(x);
            int inv = e->sg ? (tr < -ldexpl(1, w - 1) || tr >= ldexpl(1, w - 1)) : (tr <= -1 || tr >= ldexpl(1, w));
            rf = inv ? FE_INVALID : (x != tr ? FE_INEXACT : 0);
        }
        memset(out, 0, 32); e->plain(in, 0, out);
        u256 lv = 0; memcpy(&lv, out, (size_t)((e->n + 7) / 8)); lv &= mk;
        uint32_t lf = 0; e->x(in, 0, &lf);
        chk(e->name, 0, b, lv, rv, lf, rf & ~2u, 1);
    }
}

int main(void) {
    for (unsigned i = 0; i < sizeof its / sizeof its[0]; i++) run_itofp(&its[i]);
    for (unsigned i = 0; i < sizeof fts / sizeof fts[0]; i++) run_fptoi(&fts[i]);
    long n = 0, bv = 0, bf = 0, nh = 0, bh = 0, ov = 0;
    printf("\n%-26s %8s %7s %7s %8s %8s %6s\n", "operation", "cases", "badval", "badflag", "vs host", "badhost", "CR>host");
    for (int i = 0; i < nst; i++) {
        Stat *s = &st[i]; n += s->n; bv += s->badv; bf += s->badf; nh += s->nhost; bh += s->badhost; ov += s->over;
        printf("%-26s %8ld %7ld %7ld %8ld %8ld %6ld\n", s->op, s->n, s->badv, s->badf, s->nhost, s->badhost, s->over);
    }
    printf("\nTOTAL int cases %ld, value mismatches %ld, flag mismatches %ld, operations %d; "
           "reference against the host value: %ld compared, %ld differ, %ld where CR §2 overrides the host\n",
           n, bv, bf, nst, nh, bh, ov);
    return (bv || bf || bh) ? 1 : 0;
}
