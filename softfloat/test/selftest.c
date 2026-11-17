/* selftest.c: the patched SoftFloat roots (native build, no quantum, no checker) against the host's
 * x86-64 hardware floats, bit for bit, with rounding modes and exception flags.
 *
 * Build and run: softfloat/test/run_selftest.sh. Every root of cqsf_roots.h is called as ordinary host
 * code. The reference is this file compiled by clang 19 -O1 with FENV_ACCESS on (constrained FP ops),
 * -msse4.1 -mf16c -mfma: SSE/x87 instructions for f32/f64/f80, F16C conversions for f16 (an f16 op is
 * the f32 op rounded once more to f16, exact for + - * / sqrt since 24 >= 2*11+2), libm for fmod and
 * round. Where the CR §2 table fixes a result that native code leaves to a library (a NaN of frem or
 * fma, fmax/fmin, the flags of a compiler-rt conversion), the expected value is computed here from the
 * CR row instead, and the report says so per operation. */
#pragma STDC FENV_ACCESS ON
#include <fenv.h>
#include <float.h>
#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <immintrin.h>
#include "cqsf_roots.h"

typedef uint64_t u64;
typedef struct { u64 v; unsigned f; } R;
#define FE_ALL (FE_INVALID | FE_DIVBYZERO | FE_OVERFLOW | FE_UNDERFLOW | FE_INEXACT)
static const int MODES[4] = {FE_TONEAREST, FE_DOWNWARD, FE_UPWARD, FE_TOWARDZERO};
static void hbegin(int m) { fesetround(m); feclearexcept(FE_ALL_EXCEPT); }
static unsigned hend(void) { unsigned f = (unsigned)fetestexcept(FE_ALL); fesetround(FE_TONEAREST); return f; }

/* ---- formats ---- */
static inline _Float16 H(u64 b) { uint16_t x = (uint16_t)b; _Float16 r; memcpy(&r, &x, 2); return r; }
static inline u64 Hb(_Float16 v) { uint16_t x; memcpy(&x, &v, 2); return x; }
static inline __bf16 Bf(u64 b) { uint16_t x = (uint16_t)b; __bf16 r; memcpy(&r, &x, 2); return r; }
static inline u64 Bb(__bf16 v) { uint16_t x; memcpy(&x, &v, 2); return x; }
static inline float S(u64 b) { uint32_t x = (uint32_t)b; float r; memcpy(&r, &x, 4); return r; }
static inline u64 Sb(float v) { uint32_t x; memcpy(&x, &v, 4); return x; }
static inline double D(u64 b) { double r; memcpy(&r, &b, 8); return r; }
static inline u64 Db(double v) { u64 x; memcpy(&x, &v, 8); return x; }

typedef struct { const char *name; int bits, ebits, fbits; } Fmt;
static const Fmt FH = {"f16", 16, 5, 10}, FB = {"bf16", 16, 8, 7}, FS = {"f32", 32, 8, 23}, FD = {"f64", 64, 11, 52};
static u64 sign_of(const Fmt *F) { return (u64)1 << (F->bits - 1); }
static u64 expmask(const Fmt *F) { return (((u64)1 << F->ebits) - 1) << F->fbits; }
static u64 fracmask(const Fmt *F) { return ((u64)1 << F->fbits) - 1; }
static u64 quietbit(const Fmt *F) { return (u64)1 << (F->fbits - 1); }
static int isnanb(const Fmt *F, u64 a) { return (a & expmask(F)) == expmask(F) && (a & fracmask(F)); }
static int issnanb(const Fmt *F, u64 a) { return isnanb(F, a) && !(a & quietbit(F)); }
static u64 defnan(const Fmt *F) { return sign_of(F) | expmask(F) | quietbit(F); }


/* The host's bf16 conversions are compiler-rt calls (they ignore the mode and raise no flags); clang 19
 * cannot compile them as strict FP ops on x86 ("soft promote"), so they live in host_bf16.c. */
u64 hb_from_s(u64 a); u64 hb_from_d(u64 a); u64 hb_from_i64(int64_t v); u64 hb_from_u64(uint64_t v); u64 hb_from_f(float v);
bool lb_is_fpclass(u64 a, uint32_t mask);
u64 lb_fpext_f32(u64 a); uint32_t lb_fpext_f32_x(u64 a); u64 lb_fpext_f64(u64 a); uint32_t lb_fpext_f64_x(u64 a);
u64 lb_fptrunc_s(u64 a); u64 lb_fptrunc_s_m(u64 a, uint32_t m); uint32_t lb_fptrunc_s_x(u64 a, uint32_t m);
u64 lb_fptrunc_d(u64 a); u64 lb_fptrunc_d_m(u64 a, uint32_t m); uint32_t lb_fptrunc_d_x(u64 a, uint32_t m);
#define LBDECL(N, TS, TU) u64 lb_sitofp_##N(TS); u64 lb_sitofp_##N##_m(TS, uint32_t); uint32_t lb_sitofp_##N##_x(TS, uint32_t); \
    u64 lb_uitofp_##N(TU); u64 lb_uitofp_##N##_m(TU, uint32_t); uint32_t lb_uitofp_##N##_x(TU, uint32_t);
LBDECL(1, bool, bool) LBDECL(8, int8_t, uint8_t) LBDECL(16, int16_t, uint16_t) LBDECL(32, int32_t, uint32_t) LBDECL(64, int64_t, uint64_t)
void lb_fptoint(u64 a, u64 v[8], uint32_t f[8]);

/* ---- inputs ---- */
static u64 rng = 0x9E3779B97F4A7C15u;
static u64 rnd(void) { rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17; return rng; }

static int specials(const Fmt *F, u64 *out) {
    int n = 0; u64 s = sign_of(F), e = expmask(F), fm = fracmask(F), q = quietbit(F);
    u64 one = (((u64)1 << (F->ebits - 1)) - 1) << F->fbits;           /* 1.0 */
    u64 base[] = {0, 1, fm, (u64)1 << F->fbits, one, one | 1, one | (q), one + ((u64)1 << F->fbits) /* 2 */,
                  one + ((u64)2 << F->fbits) | q /* 6 */, e - 1 /* max */, e - ((u64)1 << F->fbits) /* max binade */,
                  e /* inf */, e | q /* qnan */, e | q | 5, e | 1 /* snan */, e | (q >> 1) | 3, one - ((u64)1 << F->fbits) | q /* 0.75 */,
                  one - ((u64)1 << F->fbits) /* 0.5 */, one + ((u64)F->fbits << F->fbits) /* 2^fbits */,
                  (one + ((u64)F->fbits << F->fbits)) | 1, q /* subnormal */, fm - 1};
    for (unsigned i = 0; i < sizeof base / sizeof base[0]; i++) { out[n++] = base[i]; out[n++] = base[i] | s; }
    return n;
}
/* A random operand: half uniform bits, half a value near 1 (a tame exponent spread). */
static u64 rndval(const Fmt *F) {
    u64 r = rnd();
    if (r & 1) return (r >> 1) & ((F->bits == 64) ? ~(u64)0 : (((u64)1 << F->bits) - 1));
    u64 bias = ((u64)1 << (F->ebits - 1)) - 1;
    int spread = F->ebits >= 8 ? 40 : 12;
    u64 ex = bias + (u64)((int)((rnd() % (2 * spread + 1))) - spread);
    return ((rnd() & 1) ? sign_of(F) : 0) | (ex << F->fbits) | (rnd() & fracmask(F));
}

/* ---- bookkeeping ---- */
typedef struct { const char *op; long n, badv, badf; int flags_checked; const char *note; } Stat;
static Stat stats[2048]; static int nstats;
static Stat *stat_of(const char *op) {
    for (int i = 0; i < nstats; i++) if (!strcmp(stats[i].op, op)) return &stats[i];
    stats[nstats].op = strdup(op); stats[nstats].flags_checked = 1; return &stats[nstats++];
}
static void check(const char *op, int mode, const u64 *in, int nin, R lib, R ref, int cmpflags) {
    Stat *s = stat_of(op); s->n++;
    if (!cmpflags) s->flags_checked = 0;
    int bv = lib.v != ref.v, bf = cmpflags && lib.f != ref.f;
    if (bv) s->badv++;
    if (bf) s->badf++;
    if ((bv || bf) && (s->badv + s->badf) <= 3) {
        printf("MISMATCH %-26s mode %4d in", op, mode);
        for (int i = 0; i < nin; i++) printf(" %#" PRIx64, in[i]);
        printf(": lib %#" PRIx64 " f%02x, ref %#" PRIx64 " f%02x\n", lib.v, lib.f, ref.v, ref.f);
    }
}
static void note(const char *op, const char *n) { stat_of(op)->note = n; }

/* x86 flag bits (CR §1.2) are the macOS x86-64 FE_* values. */
_Static_assert(FE_INVALID == 1 && FE_DIVBYZERO == 4 && FE_OVERFLOW == 8 && FE_UNDERFLOW == 16 && FE_INEXACT == 32, "x86");

/* ---- host references ---- */
#define HBIN(N, T, TOB, FROMB, EXPR)                                                                   \
static R N(u64 a, u64 b, int m) { volatile T x = FROMB(a), y = FROMB(b); hbegin(m); T r = EXPR; unsigned f = hend(); return (R){TOB(r), f}; }
HBIN(h_add_D, double, Db, D, x + y) HBIN(h_sub_D, double, Db, D, x - y) HBIN(h_mul_D, double, Db, D, x * y) HBIN(h_div_D, double, Db, D, x / y)
HBIN(h_add_S, float, Sb, S, x + y) HBIN(h_sub_S, float, Sb, S, x - y) HBIN(h_mul_S, float, Sb, S, x * y) HBIN(h_div_S, float, Sb, S, x / y)
HBIN(h_add_H, _Float16, Hb, H, x + y) HBIN(h_sub_H, _Float16, Hb, H, x - y) HBIN(h_mul_H, _Float16, Hb, H, x * y) HBIN(h_div_H, _Float16, Hb, H, x / y)
HBIN(h_rem_D, double, Db, D, fmod(x, y)) HBIN(h_rem_S, float, Sb, S, fmodf(x, y)) HBIN(h_rem_H, _Float16, Hb, H, (_Float16)fmodf((float)x, (float)y))
#define HUN(N, T, TOB, FROMB, EXPR)                                                                    \
static R N(u64 a, int m) { volatile T x = FROMB(a); hbegin(m); T r = EXPR; unsigned f = hend(); return (R){TOB(r), f}; }
HUN(h_sqrt_D, double, Db, D, __builtin_sqrt(x)) HUN(h_sqrt_S, float, Sb, S, __builtin_sqrtf(x)) HUN(h_sqrt_H, _Float16, Hb, H, (_Float16)__builtin_sqrtf((float)x))
HUN(h_floor_D, double, Db, D, __builtin_floor(x)) HUN(h_ceil_D, double, Db, D, __builtin_ceil(x)) HUN(h_trunc_D, double, Db, D, __builtin_trunc(x))
HUN(h_rint_D, double, Db, D, __builtin_rint(x)) HUN(h_round_D, double, Db, D, round(x))
HUN(h_floor_S, float, Sb, S, __builtin_floorf(x)) HUN(h_ceil_S, float, Sb, S, __builtin_ceilf(x)) HUN(h_trunc_S, float, Sb, S, __builtin_truncf(x))
HUN(h_rint_S, float, Sb, S, __builtin_rintf(x)) HUN(h_round_S, float, Sb, S, roundf(x))
HUN(h_floor_H, _Float16, Hb, H, (_Float16)__builtin_floorf((float)x)) HUN(h_ceil_H, _Float16, Hb, H, (_Float16)__builtin_ceilf((float)x))
HUN(h_trunc_H, _Float16, Hb, H, (_Float16)__builtin_truncf((float)x)) HUN(h_rint_H, _Float16, Hb, H, (_Float16)__builtin_rintf((float)x))
HUN(h_round_H, _Float16, Hb, H, (_Float16)roundf((float)x))
#define HTER(N, T, TOB, FROMB, EXPR)                                                                   \
static R N(u64 a, u64 b, u64 c, int m) { volatile T x = FROMB(a), y = FROMB(b), z = FROMB(c); hbegin(m); T r = EXPR; unsigned f = hend(); return (R){TOB(r), f}; }
HTER(h_fma_D, double, Db, D, __builtin_fma(x, y, z)) HTER(h_fma_S, float, Sb, S, __builtin_fmaf(x, y, z))
HTER(h_fma_H, _Float16, Hb, H, (_Float16)__builtin_fma((double)x, (double)y, (double)z))

/* CR §2 NaN row: the first NaN operand quieted; an invalid operation gives the default NaN. */
static u64 cr_nan(const Fmt *F, const u64 *in, int n) {
    for (int i = 0; i < n; i++) if (isnanb(F, in[i])) return in[i] | quietbit(F);
    return defnan(F);
}

/* f16 fma: a*b + c is exact in x87 long double (22 product bits; the sum spans at most 64 bits), then
 * one rounding to f16 in the mode, computed here with frndint at the f16 exponent. NaNs by CR §2. */
static R fma16_exact(const u64 *in, int m) {
    R r = {0, 0};
    _Float16 a = H(in[0]), b = H(in[1]), c = H(in[2]);
    if (isnanb(&FH, in[0]) || isnanb(&FH, in[1]) || isnanb(&FH, in[2])) {
        r.v = cr_nan(&FH, in, 3);
        r.f = (issnanb(&FH, in[0]) || issnanb(&FH, in[1]) || issnanb(&FH, in[2])) ? FE_INVALID : 0;
        return r;
    }
    volatile long double x = (long double)a, y = (long double)b, z = (long double)c;
    hbegin(m);
    long double s = x * y + z;
    unsigned f0 = hend();
    if (f0 & FE_INVALID) { r.v = defnan(&FH); r.f = FE_INVALID; return r; }        /* inf*0, inf-inf */
    if (isinf(s)) { r.v = Hb((_Float16)(float)s); return r; }                         /* an exact infinity */
    if (s == 0) {                                                               /* exact zero: IEEE sign rule */
        int ps = signbit((double)a) ^ signbit((double)b), cs = signbit((double)c);
        int neg = (x * y == 0 && ps == cs) ? ps : (m == FE_DOWNWARD);
        r.v = neg ? 0x8000 : 0; return r;
    }
    int e = ilogbl(s); if (e < -14) e = -14;                                    /* f16 quantum 2^(e-10) */
    hbegin(m);
    long double q = rintl(ldexpl(s, 10 - e));                                   /* x87 frndint in the mode */
    hend();
    long double v = ldexpl(q, e - 10);
    int inexact = v != s;
    long double av = fabsl(v);
    if (av > 65504.0L) {                                                        /* overflow */
        int up = (m == FE_TONEAREST) || (m == FE_UPWARD && s > 0) || (m == FE_DOWNWARD && s < 0);
        r.v = (s < 0 ? 0x8000 : 0) | (up ? 0x7C00 : 0x7BFF); r.f = FE_OVERFLOW | FE_INEXACT; return r;
    }
    r.v = Hb((_Float16)(float)v);                                               /* exact */
    if (inexact) {
        r.f = FE_INEXACT;
        /* tiny after rounding: the value rounded to 11 bits with unbounded exponent is below 2^-14 */
        int e2 = ilogbl(s);
        hbegin(m); long double q2 = rintl(ldexpl(s, 10 - e2)); hend();
        if (fabsl(ldexpl(q2, e2 - 10)) < 0x1p-14L) r.f |= FE_UNDERFLOW;
    }
    return r;
}

/* ---- the drivers ---- */
typedef struct {
    const char *stem; const Fmt *F; int arity; int has_mode;
    R (*host)();          /* (a[, b[, c]], mode) */
    void *plain, *m, *x;  /* roots */
    int nan_by_cr;        /* a NaN result is checked against the CR row, not the host */
    int flags;            /* compare flags with the host */
    const char *why;
} ArOp;

#define CALLF(F, ret, fn, ...) ret

/* Root calls through the C float types, per format. */
#define ROOTCALLS(FT, T, TOB, FROMB)                                                                   \
static u64 call_plain_##FT(void *f, int ar, const u64 *a) {                                           \
    if (ar == 1) return TOB(((T(*)(T))f)(FROMB(a[0])));                                                 \
    if (ar == 2) return TOB(((T(*)(T, T))f)(FROMB(a[0]), FROMB(a[1])));                                \
    return TOB(((T(*)(T, T, T))f)(FROMB(a[0]), FROMB(a[1]), FROMB(a[2])));                              \
}                                                                                                       \
static u64 call_m_##FT(void *f, int ar, const u64 *a, uint32_t m) {                                   \
    if (ar == 1) return TOB(((T(*)(T, uint32_t))f)(FROMB(a[0]), m));                                    \
    if (ar == 2) return TOB(((T(*)(T, T, uint32_t))f)(FROMB(a[0]), FROMB(a[1]), m));                   \
    return TOB(((T(*)(T, T, T, uint32_t))f)(FROMB(a[0]), FROMB(a[1]), FROMB(a[2]), m));                 \
}                                                                                                       \
static unsigned call_x_##FT(void *f, int ar, int hasm, const u64 *a, uint32_t m) {                     \
    if (hasm) {                                                                                         \
        if (ar == 1) return ((uint32_t(*)(T, uint32_t))f)(FROMB(a[0]), m);                              \
        if (ar == 2) return ((uint32_t(*)(T, T, uint32_t))f)(FROMB(a[0]), FROMB(a[1]), m);             \
        return ((uint32_t(*)(T, T, T, uint32_t))f)(FROMB(a[0]), FROMB(a[1]), FROMB(a[2]), m);           \
    }                                                                                                   \
    if (ar == 1) return ((uint32_t(*)(T))f)(FROMB(a[0]));                                               \
    return ((uint32_t(*)(T, T))f)(FROMB(a[0]), FROMB(a[1]));                                            \
}
ROOTCALLS(H, _Float16, Hb, H) ROOTCALLS(S, float, Sb, S) ROOTCALLS(D, double, Db, D)

static void run_arith(const ArOp *o) {
    const Fmt *F = o->F; u64 sp[64]; int ns = specials(F, sp);
    char name[96];
    long ncases = 0;
    u64 in[3];
    for (int pass = 0; pass < 2; pass++) {
        long total = pass == 0 ? (o->arity == 1 ? ns : o->arity == 2 ? (long)ns * ns : 20L * 20 * 20) : 4000;
        for (long t = 0; t < total; t++) {
            if (pass == 0) {
                if (o->arity == 1) in[0] = sp[t];
                else if (o->arity == 2) { in[0] = sp[t / ns]; in[1] = sp[t % ns]; }
                else { in[0] = sp[(t / 400) * 2 % ns]; in[1] = sp[((t / 20) % 20) * 2 % ns + (t & 1)]; in[2] = sp[(t % 20) * 2 % ns + ((t >> 1) & 1)]; }
            } else for (int i = 0; i < o->arity; i++) in[i] = rndval(F);
            for (int mi = 0; mi < (o->has_mode ? 4 : 1); mi++) {
                int m = MODES[mi];
                R ref = o->arity == 1 ? ((R(*)(u64, int))o->host)(in[0], m)
                      : o->arity == 2 ? ((R(*)(u64, u64, int))o->host)(in[0], in[1], m)
                      : ((R(*)(u64, u64, u64, int))o->host)(in[0], in[1], in[2], m);
                if (o->nan_by_cr && isnanb(F, ref.v)) ref.v = cr_nan(F, in, o->arity);
                if (o->host == (R(*)())h_rem_D || o->host == (R(*)())h_rem_S || o->host == (R(*)())h_rem_H) {
                    /* fmod is exact; IEEE/CR §2: INVALID for an sNaN, or x = ±Inf or y = ±0 with no NaN */
                    int anynan = isnanb(F, in[0]) || isnanb(F, in[1]);
                    int inf = (in[0] & ~sign_of(F)) == expmask(F), zero = !(in[1] & ~sign_of(F));
                    ref.f = (issnanb(F, in[0]) || issnanb(F, in[1]) || (!anynan && (inf || zero))) ? FE_INVALID : 0;
                }
                if (o->host == (R(*)())h_fma_H) ref = fma16_exact(in, m);
                R lib;
                u64 (*cp)(void *, int, const u64 *) = F == &FH ? call_plain_H : F == &FS ? call_plain_S : call_plain_D;
                u64 (*cm)(void *, int, const u64 *, uint32_t) = F == &FH ? call_m_H : F == &FS ? call_m_S : call_m_D;
                unsigned (*cx)(void *, int, int, const u64 *, uint32_t) = F == &FH ? call_x_H : F == &FS ? call_x_S : call_x_D;
                if (mi == 0) {
                    lib.v = cp(o->plain, o->arity, in); lib.f = cx(o->x, o->arity, o->has_mode, in, 0);
                    snprintf(name, sizeof name, "%s", o->stem);
                    check(name, m, in, o->arity, lib, ref, o->flags);
                }
                if (o->has_mode) {
                    lib.v = cm(o->m, o->arity, in, (uint32_t)m); lib.f = cx(o->x, o->arity, 1, in, (uint32_t)m);
                    snprintf(name, sizeof name, "%s_rm", o->stem);
                    check(name, m, in, o->arity, lib, ref, o->flags);
                }
                ncases++;
            }
        }
    }
    if (o->why) { note(o->stem, o->why); if (o->has_mode) { snprintf(name, sizeof name, "%s_rm", o->stem); note(name, o->why); } }
}

#define AR1(STEM, FMT, AR_, HOST, NANCR, FL, WHY) \
    { #STEM, &FMT, AR_, 1, (R(*)())HOST, (void *)cqsf_##STEM, (void *)cqsf_##STEM##_m, (void *)cqsf_##STEM##_x, NANCR, FL, WHY }
#define AR0(STEM, FMT, AR_, HOST, NANCR, FL, WHY) \
    { #STEM, &FMT, AR_, 0, (R(*)())HOST, (void *)cqsf_##STEM, 0, (void *)cqsf_##STEM##_x, NANCR, FL, WHY }
#define AR(STEM, FMT, AR_, HM, HOST, NANCR, FL, WHY) AR##HM(STEM, FMT, AR_, HOST, NANCR, FL, WHY)

static const char *W_FREM = "value: libm fmod; NaN and flags by CR §2 (libm's fmod(0, 0) raises no INVALID)";
static const char *W_FMA = "NaN by CR §2 (vfmadd picks by encoding)";
static const char *W_F16FMA = "reference: the exact sum in x87 long double, rounded to f16 here; NaN by CR §2";

/* fmax/fmin: the CR row and IEEE flags, computed here (native leaves them to codegen/libm). */
static R cr_fmax(const Fmt *F, u64 a, u64 b, int min) {
    R r; r.f = (issnanb(F, a) || issnanb(F, b)) ? FE_INVALID : 0;
    if (isnanb(F, a)) { r.v = b; return r; }
    if (isnanb(F, b)) { r.v = a; return r; }
    double x = F == &FH ? (double)H(a) : F == &FS ? (double)S(a) : D(a);
    double y = F == &FH ? (double)H(b) : F == &FS ? (double)S(b) : D(b);
    r.v = (min ? y < x : y > x) ? b : a; return r;
}
static void run_minmax(const Fmt *F, const char *stem, void *plain, void *x, int min) {
    u64 sp[64]; int ns = specials(F, sp); u64 in[2];
    u64 (*cp)(void *, int, const u64 *) = F == &FH ? call_plain_H : F == &FS ? call_plain_S : call_plain_D;
    unsigned (*cx)(void *, int, int, const u64 *, uint32_t) = F == &FH ? call_x_H : F == &FS ? call_x_S : call_x_D;
    for (long t = 0; t < (long)ns * ns + 4000; t++) {
        if (t < (long)ns * ns) { in[0] = sp[t / ns]; in[1] = sp[t % ns]; } else { in[0] = rndval(F); in[1] = rndval(F); }
        R ref = cr_fmax(F, in[0], in[1], min), lib = {cp(plain, 2, in), cx(x, 2, 0, in, 0)};
        check(stem, 0, in, 2, lib, ref, 1);
    }
    note(stem, "reference: the CR §2 row and IEEE INVALID for an sNaN, computed here");
}

/* ---- compares ---- */
typedef bool (*Cmp)();
static int host_pred(const char *p, double x, double y) {
    int un = __builtin_isunordered(x, y), lt = __builtin_isless(x, y), gt = __builtin_isgreater(x, y), eq = !un && !lt && !gt;
    if (!strcmp(p, "oeq")) return eq; if (!strcmp(p, "ogt")) return gt; if (!strcmp(p, "oge")) return gt || eq;
    if (!strcmp(p, "olt")) return lt; if (!strcmp(p, "ole")) return lt || eq; if (!strcmp(p, "one")) return lt || gt;
    if (!strcmp(p, "ord")) return !un; if (!strcmp(p, "uno")) return un; if (!strcmp(p, "ueq")) return un || eq;
    if (!strcmp(p, "ugt")) return un || gt; if (!strcmp(p, "uge")) return un || gt || eq; if (!strcmp(p, "ult")) return un || lt;
    if (!strcmp(p, "ule")) return un || lt || eq; if (!strcmp(p, "une")) return !eq; abort();
}
static unsigned host_cmpflags_f64(u64 a, u64 b, int sig) {
    volatile double x = D(a), y = D(b); volatile int r; hbegin(FE_TONEAREST); r = sig ? (x <= y) : (x == y); unsigned f = hend(); (void)r; return f;
}
static unsigned host_cmpflags_f32(u64 a, u64 b, int sig) {
    volatile float x = S(a), y = S(b); volatile int r; hbegin(FE_TONEAREST); r = sig ? (x <= y) : (x == y); unsigned f = hend(); (void)r; return f;
}
static unsigned host_cmpflags_f16(u64 a, u64 b, int sig) {
    volatile _Float16 x = H(a), y = H(b); volatile int r; hbegin(FE_TONEAREST); r = sig ? (x <= y) : (x == y); unsigned f = hend(); (void)r; return f;
}
static const char *PREDS[] = {"oeq", "ogt", "oge", "olt", "ole", "one", "ord", "ueq", "ugt", "uge", "ult", "ule", "une", "uno"};

#define CMPS(FT, T, FMT, FROMB)                                                                         \
static void run_cmp_##FT(void) {                                                                        \
    Cmp fp[14] = {(Cmp)cqsf_fcmp_oeq_##FT, (Cmp)cqsf_fcmp_ogt_##FT, (Cmp)cqsf_fcmp_oge_##FT, (Cmp)cqsf_fcmp_olt_##FT, \
        (Cmp)cqsf_fcmp_ole_##FT, (Cmp)cqsf_fcmp_one_##FT, (Cmp)cqsf_fcmp_ord_##FT, (Cmp)cqsf_fcmp_ueq_##FT,       \
        (Cmp)cqsf_fcmp_ugt_##FT, (Cmp)cqsf_fcmp_uge_##FT, (Cmp)cqsf_fcmp_ult_##FT, (Cmp)cqsf_fcmp_ule_##FT,       \
        (Cmp)cqsf_fcmp_une_##FT, (Cmp)cqsf_fcmp_uno_##FT};                                              \
    u64 sp[64]; int ns = specials(&FMT, sp); u64 in[2]; char name[64];                                  \
    for (long t = 0; t < (long)ns * ns + 4000; t++) {                                                   \
        if (t < (long)ns * ns) { in[0] = sp[t / ns]; in[1] = sp[t % ns]; } else { in[0] = rndval(&FMT); in[1] = rndval(&FMT); } \
        T x = FROMB(in[0]), y = FROMB(in[1]);                                                           \
        for (int p = 0; p < 14; p++) {                                                                  \
            R lib = {((bool(*)(T, T))fp[p])(x, y), 0}, ref = {(u64)host_pred(PREDS[p], (double)x, (double)y), 0}; \
            snprintf(name, sizeof name, "fcmp_%s_" #FT, PREDS[p]); check(name, 0, in, 2, lib, ref, 1);   \
        }                                                                                               \
        R lq = {0, cqsf_fcmpq_##FT##_x(x, y)}, rq = {0, host_cmpflags_##FT(in[0], in[1], 0)};           \
        check("fcmp_*_" #FT "_exc", 0, in, 2, lq, rq, 1);                                               \
        R ls = {0, cqsf_fcmps_##FT##_x(x, y)}, rs = {0, host_cmpflags_##FT(in[0], in[1], 1)};           \
        check("fcmps_*_" #FT "_exc", 0, in, 2, ls, rs, 1);                                              \
    }                                                                                                   \
}
CMPS(f16, _Float16, FH, H) CMPS(f32, float, FS, S) CMPS(f64, double, FD, D)

/* ---- is_fpclass ---- */
static unsigned cls(const Fmt *F, u64 a) {
    int neg = (a & sign_of(F)) != 0; u64 e = a & expmask(F), f = a & fracmask(F);
    if (e == expmask(F)) return f ? ((f & quietbit(F)) ? 1 : 0) : (neg ? 2 : 9);
    if (e) return neg ? 3 : 8;
    return f ? (neg ? 4 : 7) : (neg ? 5 : 6);
}
static void run_class(void) {
    const Fmt *Fs[] = {&FH, &FB, &FS, &FD};
    for (int fi = 0; fi < 4; fi++) {
        const Fmt *F = Fs[fi]; u64 sp[64]; int ns = specials(F, sp); char name[48];
        snprintf(name, sizeof name, "is_fpclass_%s", F->name);
        for (int t = 0; t < ns + 2000; t++) {
            u64 a = t < ns ? sp[t] : rndval(F);
            /* the reference class from the host's own classification where it has one */
            unsigned c = cls(F, a);
            if (F == &FD) {
                double x = D(a); int k = fpclassify(x);
                unsigned hc = k == FP_NAN ? ((a & quietbit(F)) ? 1u : 0u) : k == FP_INFINITE ? (signbit(x) ? 2u : 9u)
                            : k == FP_NORMAL ? (signbit(x) ? 3u : 8u) : k == FP_SUBNORMAL ? (signbit(x) ? 4u : 7u) : (signbit(x) ? 5u : 6u);
                if (hc != c) { printf("is_fpclass reference disagrees with fpclassify at %#" PRIx64 "\n", a); }
            }
            for (int m = 0; m < 10; m++) {
                uint32_t mask = (1u << m) | (uint32_t)(rnd() & 0x3FF & ~(1u << c) & ~(1u << m));
                bool got = F == &FH ? cqsf_is_fpclass_f16(H(a), mask) : F == &FB ? lb_is_fpclass(a, mask)
                         : F == &FS ? cqsf_is_fpclass_f32(S(a), mask) : cqsf_is_fpclass_f64(D(a), mask);
                R lib = {got, 0}, ref = {(mask >> c) & 1, 0};
                u64 in[2] = {a, mask}; check(name, 0, in, 2, lib, ref, 1);
            }
        }
        note(name, "reference: fpclassify/signbit and the quiet bit (f64), the field test otherwise");
    }
}

/* ---- fp <-> fp ---- */
static void run_fpconv(void) {
    u64 sp[64], in[1]; char name[64];
    /* fpext */
    struct { const char *n; const Fmt *F; } ext[] = {{"fpext_f16_to_f32", &FH}, {"fpext_f16_to_f64", &FH}, {"fpext_f32_to_f64", &FS},
                                                     {"fpext_bf16_to_f32", &FB}, {"fpext_bf16_to_f64", &FB}};
    for (int k = 0; k < 5; k++) {
        const Fmt *F = ext[k].F; int ns = specials(F, sp);
        for (int t = 0; t < ns + 3000; t++) {
            in[0] = t < ns ? sp[t] : rndval(F);
            volatile u64 a = in[0]; R ref, lib;
            hbegin(FE_TONEAREST);
            switch (k) {
            case 0: ref.v = Sb((float)H(a)); break;
            case 1: ref.v = Db((double)H(a)); break;
            case 2: ref.v = Db((double)S(a)); break;
            case 3: ref.v = (u64)(uint32_t)a << 16; break;             /* CR §2: a bare shift */
            default: ref.v = Db((double)S((u64)(uint32_t)a << 16)); break;
            }
            ref.f = hend();
            switch (k) {
            case 0: lib.v = Sb(cqsf_fpext_f16_to_f32(H(a))); lib.f = cqsf_fpext_f16_to_f32_x(H(a)); break;
            case 1: lib.v = Db(cqsf_fpext_f16_to_f64(H(a))); lib.f = cqsf_fpext_f16_to_f64_x(H(a)); break;
            case 2: lib.v = Db(cqsf_fpext_f32_to_f64(S(a))); lib.f = cqsf_fpext_f32_to_f64_x(S(a)); break;
            case 3: lib.v = lb_fpext_f32(a); lib.f = lb_fpext_f32_x(a); break;
            default: lib.v = lb_fpext_f64(a); lib.f = lb_fpext_f64_x(a); break;
            }
            check(ext[k].n, 0, in, 1, lib, ref, 1);
        }
    }
    note("fpext_bf16_to_f32", "reference: the CR §2 bare shift (native: inline shift)");
    note("fpext_bf16_to_f64", "reference: shift, then the host cvtss2sd");
    /* fptrunc */
    struct { const char *n; const Fmt *F; int flags; } tr[] = {{"fptrunc_f32_to_f16", &FS, 1}, {"fptrunc_f64_to_f16", &FD, 0},
        {"fptrunc_f64_to_f32", &FD, 1}, {"fptrunc_f32_to_bf16", &FS, 0}, {"fptrunc_f64_to_bf16", &FD, 0}};
    for (int k = 0; k < 5; k++) {
        const Fmt *F = tr[k].F; int ns = specials(F, sp);
        for (int t = 0; t < ns + 3000; t++) {
            in[0] = t < ns ? sp[t] : rndval(F);
            for (int mi = 0; mi < 4; mi++) {
                int m = MODES[mi]; volatile u64 a = in[0]; R ref, lib, lm;
                hbegin(m);
                switch (k) {
                case 0: ref.v = Hb((_Float16)S(a)); break;
                case 1: ref.v = Hb((_Float16)D(a)); break;
                case 2: ref.v = Sb((float)D(a)); break;
                case 3: ref.v = hb_from_s(a); break;
                default: ref.v = hb_from_d(a); break;
                }
                ref.f = hend();
                switch (k) {
                case 0: lib.v = Hb(cqsf_fptrunc_f32_to_f16(S(a))); lm.v = Hb(cqsf_fptrunc_f32_to_f16_m(S(a), m)); lib.f = lm.f = cqsf_fptrunc_f32_to_f16_x(S(a), m); break;
                case 1: lib.v = Hb(cqsf_fptrunc_f64_to_f16(D(a))); lm.v = Hb(cqsf_fptrunc_f64_to_f16_m(D(a), m)); lib.f = lm.f = cqsf_fptrunc_f64_to_f16_x(D(a), m); break;
                case 2: lib.v = Sb(cqsf_fptrunc_f64_to_f32(D(a))); lm.v = Sb(cqsf_fptrunc_f64_to_f32_m(D(a), m)); lib.f = lm.f = cqsf_fptrunc_f64_to_f32_x(D(a), m); break;
                case 3: lib.v = lb_fptrunc_s(a); lm.v = lb_fptrunc_s_m(a, m); lib.f = lm.f = lb_fptrunc_s_x(a, m); break;
                default: lib.v = lb_fptrunc_d(a); lm.v = lb_fptrunc_d_m(a, m); lib.f = lm.f = lb_fptrunc_d_x(a, m); break;
                }
                /* compiler-rt conversions (f64 -> f16, -> bf16) round to nearest even whatever the mode */
                int crt = !tr[k].flags;
                if (mi == 0) check(tr[k].n, m, in, 1, lib, ref, tr[k].flags);
                snprintf(name, sizeof name, "%s_rm", tr[k].n);
                if (!crt || mi == 0) check(name, m, in, 1, lm, ref, tr[k].flags);
            }
        }
        if (!tr[k].flags) {
            note(tr[k].n, "reference: compiler-rt (LLVM's libcall): values only, RNE only, it raises no flags");
            snprintf(name, sizeof name, "%s_rm", tr[k].n); note(name, "RNE only (compiler-rt ignores the mode); values only");
        }
    }
}

/* ---- int -> fp ---- */
static int64_t sext_n(u64 v, int n) { return n == 64 ? (int64_t)v : (int64_t)(v << (64 - n)) >> (64 - n); }
static u64 zext_n(u64 v, int n) { return n == 64 ? v : v & (((u64)1 << n) - 1); }
static u64 rndint(int n) {
    u64 r = rnd();
    switch (rnd() % 4) { case 0: return zext_n(r, n); case 1: return zext_n(r >> (rnd() % 64), n);
    case 2: return zext_n((u64)1 << (rnd() % n), n) + (rnd() % 3) - 1; default: return zext_n(~(r >> (rnd() % 64)), n); }
}
#define I2F(N, TS, TU)                                                                                  \
static void run_itofp_##N(void) {                                                                        \
    u64 in[1]; char name[64];                                                                            \
    for (int t = 0; t < 6000; t++) {                                                                     \
        in[0] = t < 4 ? (u64[]){0, 1, zext_n(~(u64)0, N), zext_n((u64)1 << (N - 1), N)}[t] : rndint(N); \
        TS s = (TS)sext_n(in[0], N); TU u = (TU)zext_n(in[0], N);                                       \
        for (int mi = 0; mi < 4; mi++) {                                                                \
            int m = MODES[mi]; volatile TS vs = s; volatile TU vu = u; R ref, lib, lm;                 \
            /* f64 */                                                                                     \
            hbegin(m); ref.v = Db((double)vs); ref.f = hend();                                           \
            lib.v = Db(cqsf_sitofp_i##N##_to_f64(s)); lm.v = Db(cqsf_sitofp_i##N##_to_f64_m(s, m)); lib.f = lm.f = cqsf_sitofp_i##N##_to_f64_x(s, m); \
            if (!mi) check("sitofp_i" #N "_to_f64", m, in, 1, lib, ref, 1); check("sitofp_i" #N "_to_f64_rm", m, in, 1, lm, ref, 1); \
            hbegin(m); ref.v = Db((double)vu); ref.f = hend();                                           \
            lib.v = Db(cqsf_uitofp_i##N##_to_f64(u)); lm.v = Db(cqsf_uitofp_i##N##_to_f64_m(u, m)); lib.f = lm.f = cqsf_uitofp_i##N##_to_f64_x(u, m); \
            if (!mi) check("uitofp_i" #N "_to_f64", m, in, 1, lib, ref, 1); check("uitofp_i" #N "_to_f64_rm", m, in, 1, lm, ref, 1); \
            /* f32 */                                                                                     \
            hbegin(m); ref.v = Sb((float)vs); ref.f = hend();                                            \
            lib.v = Sb(cqsf_sitofp_i##N##_to_f32(s)); lm.v = Sb(cqsf_sitofp_i##N##_to_f32_m(s, m)); lib.f = lm.f = cqsf_sitofp_i##N##_to_f32_x(s, m); \
            if (!mi) check("sitofp_i" #N "_to_f32", m, in, 1, lib, ref, 1); check("sitofp_i" #N "_to_f32_rm", m, in, 1, lm, ref, 1); \
            hbegin(m); ref.v = Sb((float)vu); ref.f = hend();                                            \
            lib.v = Sb(cqsf_uitofp_i##N##_to_f32(u)); lm.v = Sb(cqsf_uitofp_i##N##_to_f32_m(u, m)); lib.f = lm.f = cqsf_uitofp_i##N##_to_f32_x(u, m); \
            if (!mi) check("uitofp_i" #N "_to_f32", m, in, 1, lib, ref, 1); check("uitofp_i" #N "_to_f32_rm", m, in, 1, lm, ref, 1); \
            /* f16 */                                                                                     \
            hbegin(m); ref.v = Hb((_Float16)vs); ref.f = hend();                                         \
            lib.v = Hb(cqsf_sitofp_i##N##_to_f16(s)); lm.v = Hb(cqsf_sitofp_i##N##_to_f16_m(s, m)); lib.f = lm.f = cqsf_sitofp_i##N##_to_f16_x(s, m); \
            if (!mi) check("sitofp_i" #N "_to_f16", m, in, 1, lib, ref, 1); check("sitofp_i" #N "_to_f16_rm", m, in, 1, lm, ref, 1); \
            hbegin(m); ref.v = Hb((_Float16)vu); ref.f = hend();                                         \
            lib.v = Hb(cqsf_uitofp_i##N##_to_f16(u)); lm.v = Hb(cqsf_uitofp_i##N##_to_f16_m(u, m)); lib.f = lm.f = cqsf_uitofp_i##N##_to_f16_x(u, m); \
            if (!mi) check("uitofp_i" #N "_to_f16", m, in, 1, lib, ref, 1); check("uitofp_i" #N "_to_f16_rm", m, in, 1, lm, ref, 1); \
            /* bf16: the host's own route (codegen: iN -> f32, then compiler-rt f32 -> bf16), RNE only */ \
            if (!mi) {                                                                                     \
                ref.v = hb_from_i64(vs); ref.f = 0;                                       \
                lib.v = lb_sitofp_##N(s); lib.f = 0; check("sitofp_i" #N "_to_bf16", m, in, 1, lib, ref, 0); \
                ref.v = hb_from_u64(vu); ref.f = 0;                                       \
                lib.v = lb_uitofp_##N(u); lib.f = 0; check("uitofp_i" #N "_to_bf16", m, in, 1, lib, ref, 0); \
            }                                                                                             \
        }                                                                                                 \
    }                                                                                                     \
    note("sitofp_i" #N "_to_bf16", "reference: the host's iN -> f32 -> compiler-rt bf16; values only, RNE"); \
    note("uitofp_i" #N "_to_bf16", "reference: the host's iN -> f32 -> compiler-rt bf16; values only, RNE"); \
    (void)name;                                                                                           \
}
I2F(8, int8_t, uint8_t) I2F(16, int16_t, uint16_t) I2F(32, int32_t, uint32_t) I2F(64, int64_t, uint64_t)
static void run_itofp_1(void) {
    u64 in[1];
    for (int v = 0; v < 2; v++) for (int mi = 0; mi < 4; mi++) {
        int m = MODES[mi]; in[0] = v; R ref, lib;
        ref.v = Db(v ? -1.0 : 0.0); ref.f = 0; lib.v = Db(cqsf_sitofp_i1_to_f64_m(v, m)); lib.f = cqsf_sitofp_i1_to_f64_x(v, m); check("sitofp_i1_to_f64_rm", m, in, 1, lib, ref, 1);
        ref.v = Db(v ? 1.0 : 0.0); lib.v = Db(cqsf_uitofp_i1_to_f64_m(v, m)); lib.f = cqsf_uitofp_i1_to_f64_x(v, m); check("uitofp_i1_to_f64_rm", m, in, 1, lib, ref, 1);
        ref.v = Sb(v ? -1.0f : 0.0f); lib.v = Sb(cqsf_sitofp_i1_to_f32(v)); lib.f = cqsf_sitofp_i1_to_f32_x(v, m); check("sitofp_i1_to_f32", m, in, 1, lib, ref, 1);
        ref.v = Sb(v ? 1.0f : 0.0f); lib.v = Sb(cqsf_uitofp_i1_to_f32(v)); lib.f = cqsf_uitofp_i1_to_f32_x(v, m); check("uitofp_i1_to_f32", m, in, 1, lib, ref, 1);
        ref.v = Hb(v ? (_Float16)-1.0f : (_Float16)0.0f); lib.v = Hb(cqsf_sitofp_i1_to_f16(v)); lib.f = cqsf_sitofp_i1_to_f16_x(v, m); check("sitofp_i1_to_f16", m, in, 1, lib, ref, 1);
        ref.v = hb_from_f(v ? 1.0f : 0.0f); lib.v = lb_uitofp_1(v); lib.f = lb_uitofp_1_x(v, m); check("uitofp_i1_to_bf16", m, in, 1, lib, ref, 1);
    }
}

/* ---- fp -> int: the CR §2 rows, value from c32/c64 (cvtt), flags from the host's strict conversion ---- */
static int32_t c32(double x) { return _mm_cvttsd_si32(_mm_set_sd(x)); }
static int64_t c64(double x) { return _mm_cvttsd_si64(_mm_set_sd(x)); }
static int32_t c32f(float x) { return _mm_cvtt_ss2si(_mm_set_ss(x)); }
static int64_t c64f(float x) { return _mm_cvttss_si64(_mm_set_ss(x)); }
#define F2I(FT, T, FMT, FROMB, C32, C64)                                                                 \
static void run_fptoint_##FT(void) {                                                                     \
    u64 sp[64], in[1]; int ns = specials(&FMT, sp);                                                      \
    for (int t = 0; t < ns + 6000; t++) {                                                                \
        in[0] = t < ns ? sp[t] : (t & 1) ? rndval(&FMT) : Db(0) ;                                        \
        if (t >= ns && !(t & 1)) { double v = ldexp((double)(int64_t)rnd(), -(int)(rnd() % 80)); in[0] = FMT.bits == 64 ? Db(v) : FMT.bits == 32 ? Sb((float)v) : Hb((_Float16)v); } \
        T x = FROMB(in[0]); volatile T vx = x; R lib, ref;                                               \
        double xd = (double)x; float xs = (float)xd; (void)xs;                                           \
        int32_t a32 = C32; int64_t a64 = C64;                                                            \
        int64_t r2 = FMT.bits == 64 ? c64(xd - 9223372036854775808.0) : c64f((float)(xs - 9223372036854775808.0f)); \
        u64 u64v = (u64)(a64 | (r2 & (a64 >> 63)));                                                      \
        struct { const char *n; u64 v; u64 lv; unsigned lf; unsigned hf; } c[8];                         \
        hbegin(FE_TONEAREST); volatile int8_t h8 = (int8_t)vx; unsigned f8 = hend();                     \
        hbegin(FE_TONEAREST); volatile int16_t h16 = (int16_t)vx; unsigned f16 = hend();                 \
        hbegin(FE_TONEAREST); volatile int32_t h32 = (int32_t)vx; unsigned f32 = hend();                 \
        hbegin(FE_TONEAREST); volatile int64_t h64 = (int64_t)vx; unsigned f64 = hend();                 \
        hbegin(FE_TONEAREST); volatile uint8_t hu8 = (uint8_t)vx; unsigned fu8 = hend();                 \
        hbegin(FE_TONEAREST); volatile uint16_t hu16 = (uint16_t)vx; unsigned fu16 = hend();             \
        hbegin(FE_TONEAREST); volatile uint32_t hu32 = (uint32_t)vx; unsigned fu32 = hend();             \
        hbegin(FE_TONEAREST); volatile uint64_t hu64 = (uint64_t)vx; unsigned fu64 = hend();             \
        (void)h8; (void)h16; (void)h32; (void)h64; (void)hu8; (void)hu16; (void)hu32; (void)hu64;         \
        c[0].n = "fptosi_" #FT "_to_i8";  c[0].v = (uint8_t)(int8_t)a32;  c[0].lv = (uint8_t)cqsf_fptosi_##FT##_to_i8(x);  c[0].lf = cqsf_fptosi_##FT##_to_i8_x(x);  c[0].hf = f8; \
        c[1].n = "fptosi_" #FT "_to_i16"; c[1].v = (uint16_t)(int16_t)a32; c[1].lv = (uint16_t)cqsf_fptosi_##FT##_to_i16(x); c[1].lf = cqsf_fptosi_##FT##_to_i16_x(x); c[1].hf = f16; \
        c[2].n = "fptosi_" #FT "_to_i32"; c[2].v = (uint32_t)a32;          c[2].lv = (uint32_t)cqsf_fptosi_##FT##_to_i32(x); c[2].lf = cqsf_fptosi_##FT##_to_i32_x(x); c[2].hf = f32; \
        c[3].n = "fptosi_" #FT "_to_i64"; c[3].v = (u64)a64;               c[3].lv = (u64)cqsf_fptosi_##FT##_to_i64(x);      c[3].lf = cqsf_fptosi_##FT##_to_i64_x(x); c[3].hf = f64; \
        c[4].n = "fptoui_" #FT "_to_i8";  c[4].v = (uint8_t)a32;           c[4].lv = cqsf_fptoui_##FT##_to_i8(x);  c[4].lf = cqsf_fptoui_##FT##_to_i8_x(x);  c[4].hf = fu8; \
        c[5].n = "fptoui_" #FT "_to_i16"; c[5].v = (uint16_t)a32;          c[5].lv = cqsf_fptoui_##FT##_to_i16(x); c[5].lf = cqsf_fptoui_##FT##_to_i16_x(x); c[5].hf = fu16; \
        c[6].n = "fptoui_" #FT "_to_i32"; c[6].v = (uint32_t)a64;          c[6].lv = cqsf_fptoui_##FT##_to_i32(x); c[6].lf = cqsf_fptoui_##FT##_to_i32_x(x); c[6].hf = fu32; \
        c[7].n = "fptoui_" #FT "_to_i64"; c[7].v = u64v;                   c[7].lv = cqsf_fptoui_##FT##_to_i64(x); c[7].lf = cqsf_fptoui_##FT##_to_i64_x(x); c[7].hf = fu64; \
        for (int k = 0; k < 8; k++) { R lib2 = {c[k].lv, c[k].lf}, ref2 = {c[k].v, c[k].hf}; check(c[k].n, 0, in, 1, lib2, ref2, 1); } \
        (void)lib; (void)ref;                                                                            \
    }                                                                                                    \
}
F2I(f64, double, FD, D, c32(xd), c64(xd))
F2I(f32, float, FS, S, c32f(xs), c64f(xs))
F2I(f16, _Float16, FH, H, c32f(xs), c64f(xs))

/* bf16 -> int: LLVM promotes bf16 to f32 by a shift, so the reference is the f32 conversion of the
 * shifted pattern (values: the CR rows on c32/c64; flags: the host's strict float conversion). */
static void run_fptoint_bf16(void) {
    static const char *names[8] = {"fptosi_bf16_to_i8", "fptosi_bf16_to_i16", "fptosi_bf16_to_i32", "fptosi_bf16_to_i64",
                                   "fptoui_bf16_to_i8", "fptoui_bf16_to_i16", "fptoui_bf16_to_i32", "fptoui_bf16_to_i64"};
    u64 sp[64], in[1]; int ns = specials(&FB, sp);
    for (int t = 0; t < ns + 6000; t++) {
        in[0] = t < ns ? sp[t] : rndval(&FB);
        float xs = S(in[0] << 16); volatile float vx = xs;
        int32_t a32 = c32f(xs); int64_t a64 = c64f(xs);
        int64_t r2 = c64f((float)(xs - 9223372036854775808.0f));
        u64 v[8] = {(uint8_t)(int8_t)a32, (uint16_t)(int16_t)a32, (uint32_t)a32, (u64)a64, (uint8_t)a32, (uint16_t)a32,
                    (uint32_t)a64, (u64)(a64 | (r2 & (a64 >> 63)))};
        unsigned f[8];
        hbegin(FE_TONEAREST); volatile int8_t h8 = (int8_t)vx; f[0] = hend();
        hbegin(FE_TONEAREST); volatile int16_t h16 = (int16_t)vx; f[1] = hend();
        hbegin(FE_TONEAREST); volatile int32_t h32 = (int32_t)vx; f[2] = hend();
        hbegin(FE_TONEAREST); volatile int64_t h64 = (int64_t)vx; f[3] = hend();
        hbegin(FE_TONEAREST); volatile uint8_t hu8 = (uint8_t)vx; f[4] = hend();
        hbegin(FE_TONEAREST); volatile uint16_t hu16 = (uint16_t)vx; f[5] = hend();
        hbegin(FE_TONEAREST); volatile uint32_t hu32 = (uint32_t)vx; f[6] = hend();
        hbegin(FE_TONEAREST); volatile uint64_t hu64 = (uint64_t)vx; f[7] = hend();
        (void)h8; (void)h16; (void)h32; (void)h64; (void)hu8; (void)hu16; (void)hu32; (void)hu64;
        u64 lv[8]; uint32_t lf[8]; lb_fptoint(in[0], lv, lf);
        for (int k = 0; k < 8; k++) { R lib = {lv[k], lf[k]}, ref = {v[k], f[k]}; check(names[k], 0, in, 1, lib, ref, 1); }
    }
}

/* fptoint from f16 via host F16C: (float)x is exact; the strict conversion of _Float16 is codegen's. */

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    ArOp ops[] = {
        AR(fadd_f64, FD, 2, 1, h_add_D, 0, 1, 0), AR(fsub_f64, FD, 2, 1, h_sub_D, 0, 1, 0),
        AR(fmul_f64, FD, 2, 1, h_mul_D, 0, 1, 0), AR(fdiv_f64, FD, 2, 1, h_div_D, 0, 1, 0),
        AR(frem_f64, FD, 2, 1, h_rem_D, 1, 1, W_FREM), AR(sqrt_f64, FD, 1, 1, h_sqrt_D, 0, 1, 0),
        AR(fma_f64, FD, 3, 1, h_fma_D, 1, 1, W_FMA), AR(rint_f64, FD, 1, 1, h_rint_D, 0, 1, 0),
        AR(floor_f64, FD, 1, 0, h_floor_D, 0, 1, 0), AR(ceil_f64, FD, 1, 0, h_ceil_D, 0, 1, 0),
        AR(trunc_f64, FD, 1, 0, h_trunc_D, 0, 1, 0), AR(round_f64, FD, 1, 0, h_round_D, 0, 1, "reference: libm round"),
        AR(fadd_f32, FS, 2, 1, h_add_S, 0, 1, 0), AR(fsub_f32, FS, 2, 1, h_sub_S, 0, 1, 0),
        AR(fmul_f32, FS, 2, 1, h_mul_S, 0, 1, 0), AR(fdiv_f32, FS, 2, 1, h_div_S, 0, 1, 0),
        AR(frem_f32, FS, 2, 1, h_rem_S, 1, 1, W_FREM), AR(sqrt_f32, FS, 1, 1, h_sqrt_S, 0, 1, 0),
        AR(fma_f32, FS, 3, 1, h_fma_S, 1, 1, W_FMA), AR(rint_f32, FS, 1, 1, h_rint_S, 0, 1, 0),
        AR(floor_f32, FS, 1, 0, h_floor_S, 0, 1, 0), AR(ceil_f32, FS, 1, 0, h_ceil_S, 0, 1, 0),
        AR(trunc_f32, FS, 1, 0, h_trunc_S, 0, 1, 0), AR(round_f32, FS, 1, 0, h_round_S, 0, 1, "reference: libm roundf"),
        AR(fadd_f16, FH, 2, 1, h_add_H, 0, 1, 0), AR(fsub_f16, FH, 2, 1, h_sub_H, 0, 1, 0),
        AR(fmul_f16, FH, 2, 1, h_mul_H, 0, 1, 0), AR(fdiv_f16, FH, 2, 1, h_div_H, 0, 1, 0),
        AR(frem_f16, FH, 2, 1, h_rem_H, 1, 1, W_FREM), AR(sqrt_f16, FH, 1, 1, h_sqrt_H, 0, 1, 0),
        AR(fma_f16, FH, 3, 1, h_fma_H, 1, 1, W_F16FMA), AR(rint_f16, FH, 1, 1, h_rint_H, 0, 1, 0),
        AR(floor_f16, FH, 1, 0, h_floor_H, 0, 1, 0), AR(ceil_f16, FH, 1, 0, h_ceil_H, 0, 1, 0),
        AR(trunc_f16, FH, 1, 0, h_trunc_H, 0, 1, 0), AR(round_f16, FH, 1, 0, h_round_H, 0, 1, "reference: libm roundf, then f16"),
    };
    for (unsigned i = 0; i < sizeof ops / sizeof ops[0]; i++) run_arith(&ops[i]);
    run_minmax(&FD, "fmax_f64", (void *)cqsf_fmax_f64, (void *)cqsf_fmax_f64_x, 0);
    run_minmax(&FD, "fmin_f64", (void *)cqsf_fmin_f64, (void *)cqsf_fmin_f64_x, 1);
    run_minmax(&FS, "fmax_f32", (void *)cqsf_fmax_f32, (void *)cqsf_fmax_f32_x, 0);
    run_minmax(&FS, "fmin_f32", (void *)cqsf_fmin_f32, (void *)cqsf_fmin_f32_x, 1);
    run_minmax(&FH, "fmax_f16", (void *)cqsf_fmax_f16, (void *)cqsf_fmax_f16_x, 0);
    run_minmax(&FH, "fmin_f16", (void *)cqsf_fmin_f16, (void *)cqsf_fmin_f16_x, 1);
    run_cmp_f16(); run_cmp_f32(); run_cmp_f64();
    run_class();
    run_fpconv();
    run_itofp_1(); run_itofp_8(); run_itofp_16(); run_itofp_32(); run_itofp_64();
    run_fptoint_f64(); run_fptoint_f32(); run_fptoint_f16(); run_fptoint_bf16();

    long n = 0, bv = 0, bf = 0;
    printf("\n%-28s %9s %8s %8s  %s\n", "operation", "cases", "badval", "badflag", "note");
    for (int i = 0; i < nstats; i++) {
        Stat *s = &stats[i]; n += s->n; bv += s->badv; bf += s->badf;
        char b[16];
        if (s->flags_checked) snprintf(b, sizeof b, "%ld", s->badf); else snprintf(b, sizeof b, "-");
        printf("%-28s %9ld %8ld %8s  %s\n", s->op, s->n, s->badv, b, s->note ? s->note : "");
    }
    printf("\nTOTAL cases %ld, value mismatches %ld, flag mismatches %ld, operations %d\n", n, bv, bf, nstats);
    return (bv || bf) ? 1 : 0;
}
