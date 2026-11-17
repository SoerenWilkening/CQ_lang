/* selftest_f80.c: the f80 roots (native build) against x87 long double, bit for bit, with modes and flags.
 * Build and run: softfloat/test/run_selftest.sh f80. As selftest.c: FENV_ACCESS on, the host's x87 is
 * the reference (precision control = extended, the macOS default), except where CR §2 fixes what x87
 * does not: a NaN result is the first NaN operand quieted (x87 picks the larger significand), fmod's NaN
 * and flags, fmax/fmin, is_fpclass, and f80 -> f16 (no x87 instruction; rounded here from the exact
 * value). fp -> int values come from host_f80.c, built without FENV_ACCESS (the -O1 code of CR §2). */
#pragma STDC FENV_ACCESS ON
#include <fenv.h>
#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cqsf_roots.h"

typedef uint64_t u64;
typedef struct { u64 m; unsigned e; } X;          /* f80 bits: significand, sign and exponent */
typedef struct { X v; unsigned f; } R;
#define FE_ALL (FE_INVALID | FE_DIVBYZERO | FE_OVERFLOW | FE_UNDERFLOW | FE_INEXACT)
static const int MODES[4] = {FE_TONEAREST, FE_DOWNWARD, FE_UPWARD, FE_TOWARDZERO};
static void hbegin(int m) { fesetround(m); feclearexcept(FE_ALL_EXCEPT); }
static unsigned hend(void) { unsigned f = (unsigned)fetestexcept(FE_ALL); fesetround(FE_TONEAREST); return f; }
static long double L(X x) { long double d = 0; memcpy(&d, &x.m, 8); uint16_t e = (uint16_t)x.e; memcpy((char *)&d + 8, &e, 2); return d; }
static X Xb(long double d) { X x; uint16_t e; memcpy(&x.m, &d, 8); memcpy(&e, (char *)&d + 8, 2); x.e = e; return x; }
static int xeq(X a, X b) { return a.m == b.m && a.e == b.e; }
static int noncanon(X a) { return (a.e & 0x7FFF) && !(a.m >> 63); }
static int isnanx(X a) { return (a.e & 0x7FFF) == 0x7FFF && (a.m << 1); }
static int issnanx(X a) { return isnanx(a) && (a.m >> 63) && !((a.m >> 62) & 1); }
static const X INDEF = {0xC000000000000000u, 0xFFFF};

static u64 rng = 0x13198A2E03707344u;
static u64 rnd(void) { rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17; return rng; }
static int specials(X *o) {
    X b[] = {{0, 0}, {1, 0}, {0x7FFFFFFFFFFFFFFFu, 0}, {0x8000000000000000u, 1}, {0x8000000000000000u, 0x3FFF},
             {0xC000000000000000u, 0x3FFF}, {0x8000000000000001u, 0x3FFF}, {0x8000000000000000u, 0x3FFE},
             {0xFFFFFFFFFFFFFFFFu, 0x7FFE}, {0x8000000000000000u, 0x7FFF} /* inf */, {0xC000000000000000u, 0x7FFF} /* qnan */,
             {0xC000000000000005u, 0x7FFF}, {0x8000000000000001u, 0x7FFF} /* snan */, {0xA000000000000003u, 0x7FFF},
             {0x8000000000000000u, 0x403E} /* 2^63 */, {0x8000000000000400u, 0x403E}, {0x8000000000000000u, 0x403F} /* 2^64 */,
             {0x8000000000000000u, 0x400D}, {0xC000000000000000u, 0x4000} /* 3 */, {0xA000000000000000u, 0x3FFE} /* 0.625 */,
             {0x4000000000000000u, 0x3FFF} /* unnormal */, {0x4000000000000000u, 0x7FFF} /* pseudo-nan */,
             {0, 0x7FFF} /* pseudo-inf */, {0x8000000000000005u, 0} /* pseudo-denormal */};
    int n = 0;
    for (unsigned i = 0; i < sizeof b / sizeof b[0]; i++) { o[n++] = b[i]; X s = b[i]; s.e |= 0x8000; o[n++] = s; }
    return n;
}
static X rndx(void) {
    X x; u64 r = rnd();
    if (r % 4 == 0) { x.m = rnd(); x.e = (unsigned)(rnd() & 0xFFFF); if (x.e & 0x7FFF) x.m |= (u64)1 << 63; return x; }
    x.m = rnd() | ((u64)1 << 63); x.e = (unsigned)(0x3FFF + (int)(rnd() % 161) - 80) | ((rnd() & 1) ? 0x8000 : 0); return x;
}

typedef struct { const char *op; long n, badv, badf; int fl; const char *note; } Stat;
static Stat st[512]; static int nst;
static Stat *so(const char *op) { for (int i = 0; i < nst; i++) if (!strcmp(st[i].op, op)) return &st[i]; st[nst].op = strdup(op); st[nst].fl = 1; return &st[nst++]; }
static void chk(const char *op, int m, X a, X b, int bv, int bf, u64 lv, u64 rv, unsigned lf, unsigned rf) {
    Stat *s = so(op); s->n++; s->badv += bv; s->badf += bf;
    if ((bv || bf) && s->badv + s->badf <= 3)
        printf("MISMATCH %-24s mode %4d in %#" PRIx64 ":%04x %#" PRIx64 ":%04x: lib %#" PRIx64 " f%02x ref %#" PRIx64 " f%02x\n",
               op, m, a.m, a.e, b.m, b.e, lv, lf, rv, rf);
}
static void chkx(const char *op, int m, X a, X b, R lib, R ref, int fl) {
    if (!fl) so(op)->fl = 0;
    chk(op, m, a, b, !xeq(lib.v, ref.v), fl && lib.f != ref.f, lib.v.m ^ ((u64)lib.v.e << 48), ref.v.m ^ ((u64)ref.v.e << 48), lib.f, ref.f);
}
static X crnan(X a, X b, int two) {   /* CR §2: the first NaN operand quieted, else the real indefinite */
    if (noncanon(a) || (two && noncanon(b))) return INDEF;
    if (isnanx(a)) { a.m |= (u64)3 << 62; return a; }
    if (two && isnanx(b)) { b.m |= (u64)3 << 62; return b; }
    return INDEF;
}

#define HB(N, EXPR) static R N(X a, X b, int m) { volatile long double x = L(a), y = L(b); hbegin(m); long double r = EXPR; unsigned f = hend(); return (R){Xb(r), f}; }
HB(h_add, x + y) HB(h_sub, x - y) HB(h_mul, x * y) HB(h_div, x / y) HB(h_rem, fmodl(x, y))
#define HU(N, EXPR) static R N(X a, X b, int m) { (void)b; volatile long double x = L(a); hbegin(m); long double r = EXPR; unsigned f = hend(); return (R){Xb(r), f}; }
HU(h_sqrt, __builtin_sqrtl(x)) HU(h_rint, __builtin_rintl(x)) HU(h_floor, __builtin_floorl(x)) HU(h_ceil, __builtin_ceill(x))
HU(h_trunc, __builtin_truncl(x)) HU(h_round, roundl(x))

typedef struct { const char *n; int ar, mode; R (*h)(X, X, int); void *p, *pm, *px; int nancr; } Op;
#define OP2(N, H, NC) {#N "_f80", 2, 1, H, (void *)cqsf_##N##_f80, (void *)cqsf_##N##_f80_m, (void *)cqsf_##N##_f80_x, NC}
#define OP1M(N, H) {#N "_f80", 1, 1, H, (void *)cqsf_##N##_f80, (void *)cqsf_##N##_f80_m, (void *)cqsf_##N##_f80_x, 1}
#define OP1(N, H) {#N "_f80", 1, 0, H, (void *)cqsf_##N##_f80, 0, (void *)cqsf_##N##_f80_x, 1}

static void run_op(const Op *o) {
    X sp[64]; int ns = specials(sp); char nm[64];
    long tot = (o->ar == 2 ? (long)ns * ns : ns) + 3000;
    for (long t = 0; t < tot; t++) {
        X a, b = {0, 0};
        long nsp = o->ar == 2 ? (long)ns * ns : ns;
        if (t < nsp) { a = o->ar == 2 ? sp[t / ns] : sp[t]; if (o->ar == 2) b = sp[t % ns]; } else { a = rndx(); b = rndx(); }
        for (int mi = 0; mi < (o->mode ? 4 : 1); mi++) {
            int m = MODES[mi];
            R ref = o->h(a, b, m), lib;
            /* CR §2: the NaN row (x87 natively picks the larger significand); a non-canonical operand is an
             * invalid operand, the real indefinite with INVALID (x87 does so; libm's floorl, roundl, fmodl
             * read it as a number) */
            if (isnanx(ref.v)) ref.v = crnan(a, b, o->ar == 2);
            if (o->h == h_rem) {   /* fmod: exact; INVALID for an sNaN, a non-canonical operand, x = Inf or y = 0 */
                int an = isnanx(a) || isnanx(b);
                int inv = issnanx(a) || issnanx(b) || noncanon(a) || noncanon(b) ||
                          (!an && (((a.e & 0x7FFF) == 0x7FFF) || (!(b.m) && !(b.e & 0x7FFF)) || ((b.e & 0x7FFF) == 0 && !b.m)));
                ref.f = inv ? FE_INVALID : 0;
            }
            ref.f &= ~2u;   /* DENORMAL is not an x86 exception bit of CR §1.2 */
            if (noncanon(a) || (o->ar == 2 && noncanon(b))) { ref.v = INDEF; ref.f = FE_INVALID; }
            long double la = L(a), lb = L(b);
            if (mi == 0) {
                lib.v = o->ar == 2 ? Xb(((long double (*)(long double, long double))o->p)(la, lb)) : Xb(((long double (*)(long double))o->p)(la));
                lib.f = o->mode ? (o->ar == 2 ? ((uint32_t (*)(long double, long double, uint32_t))o->px)(la, lb, 0) : ((uint32_t (*)(long double, uint32_t))o->px)(la, 0))
                                : (o->ar == 2 ? ((uint32_t (*)(long double, long double))o->px)(la, lb) : ((uint32_t (*)(long double))o->px)(la));
                chkx(o->n, m, a, b, lib, ref, 1);
            }
            if (o->mode) {
                lib.v = o->ar == 2 ? Xb(((long double (*)(long double, long double, uint32_t))o->pm)(la, lb, m)) : Xb(((long double (*)(long double, uint32_t))o->pm)(la, m));
                lib.f = o->ar == 2 ? ((uint32_t (*)(long double, long double, uint32_t))o->px)(la, lb, m) : ((uint32_t (*)(long double, uint32_t))o->px)(la, m);
                snprintf(nm, sizeof nm, "%s_rm", o->n); chkx(nm, m, a, b, lib, ref, 1);
            }
        }
    }
}

/* compares, fmax/fmin, is_fpclass */
static int canon_nan(X a) { return isnanx(a) || noncanon(a); }
static void run_misc(void) {
    X sp[64]; int ns = specials(sp);
    bool (*cmp[14])(long double, long double) = {cqsf_fcmp_oeq_f80, cqsf_fcmp_ogt_f80, cqsf_fcmp_oge_f80, cqsf_fcmp_olt_f80,
        cqsf_fcmp_ole_f80, cqsf_fcmp_one_f80, cqsf_fcmp_ord_f80, cqsf_fcmp_ueq_f80, cqsf_fcmp_ugt_f80, cqsf_fcmp_uge_f80,
        cqsf_fcmp_ult_f80, cqsf_fcmp_ule_f80, cqsf_fcmp_une_f80, cqsf_fcmp_uno_f80};
    const char *pn[14] = {"oeq", "ogt", "oge", "olt", "ole", "one", "ord", "ueq", "ugt", "uge", "ult", "ule", "une", "uno"};
    for (long t = 0; t < (long)ns * ns + 3000; t++) {
        X a = t < (long)ns * ns ? sp[t / ns] : rndx(), b = t < (long)ns * ns ? sp[t % ns] : rndx();
        volatile long double x = L(a), y = L(b);
        int un = __builtin_isunordered(x, y), lt = __builtin_isless(x, y), gt = __builtin_isgreater(x, y), eq = !un && !lt && !gt;
        int want[14] = {eq, gt, gt || eq, lt, lt || eq, lt || gt, !un, un || eq, un || gt, un || gt || eq, un || lt, un || lt || eq, !eq, un};
        char nm[48];
        for (int p = 0; p < 14; p++) { snprintf(nm, sizeof nm, "fcmp_%s_f80", pn[p]); chk(nm, 0, a, b, cmp[p](x, y) != want[p], 0, cmp[p](x, y), want[p], 0, 0); }
        hbegin(FE_TONEAREST); volatile int r1 = (x == y); unsigned fq = hend() & ~2u;
        hbegin(FE_TONEAREST); volatile int r2 = (x <= y); unsigned fs = hend() & ~2u; (void)r1; (void)r2;
        unsigned lq = cqsf_fcmpq_f80_x(x, y), ls = cqsf_fcmps_f80_x(x, y);
        chk("fcmp_*_f80_exc", 0, a, b, 0, lq != fq, 0, 0, lq, fq);
        chk("fcmps_*_f80_exc", 0, a, b, 0, ls != fs, 0, 0, ls, fs);
        /* fmax/fmin: the CR row; a non-canonical operand reads as a NaN there too (x87 compares it unordered) */
        for (int mn = 0; mn < 2; mn++) {
            X want2; unsigned wf = (issnanx(a) || issnanx(b) || noncanon(a) || noncanon(b)) ? FE_INVALID : 0;
            if (canon_nan(a)) want2 = b; else if (canon_nan(b)) want2 = a;
            else want2 = (mn ? __builtin_isless(y, x) : __builtin_isgreater(y, x)) ? b : a;
            X got = Xb(mn ? cqsf_fmin_f80(x, y) : cqsf_fmax_f80(x, y));
            unsigned gf = mn ? cqsf_fmin_f80_x(x, y) : cqsf_fmax_f80_x(x, y);
            chk(mn ? "fmin_f80" : "fmax_f80", 0, a, b, !xeq(got, want2), gf != wf, got.m ^ ((u64)got.e << 48), want2.m ^ ((u64)want2.e << 48), gf, wf);
        }
    }
    so("fmax_f80")->note = so("fmin_f80")->note = "reference: the CR §2 row (a NaN or non-canonical operand: the other one)";
    for (int t = 0; t < ns + 3000; t++) {
        X a = t < ns ? sp[t] : rndx();
        int neg = a.e >> 15, e = a.e & 0x7FFF; unsigned c;
        if (noncanon(a)) c = 1; else if (e == 0x7FFF) c = (a.m << 1) ? (((a.m >> 62) & 1) ? 1 : 0) : (neg ? 2 : 9);
        else if (e) c = neg ? 3 : 8; else c = a.m ? (neg ? 4 : 7) : (neg ? 5 : 6);
        for (int k = 0; k < 10; k++) {
            uint32_t mask = 1u << k; bool g = cqsf_is_fpclass_f80(L(a), mask);
            chk("is_fpclass_f80", 0, a, a, g != ((mask >> c) & 1), 0, g, (mask >> c) & 1, 0, 0);
        }
    }
    so("is_fpclass_f80")->note = "reference: the CR §2 row (pseudo-denormal subnormal, non-canonical a quiet NaN)";
}

/* conversions */
void hv_fptoint_f80(long double x, u64 v[8]);       /* host_f80.c: the -O1 values */
static R ld_to_f16(long double s, int m) {           /* one rounding of an exact value to f16 in the mode */
    R r = {{0, 0}, 0};
    if (s == 0) { r.v.m = signbit(s) ? 0x8000 : 0; return r; }
    if (isinf(s)) { r.v.m = s < 0 ? 0xFC00 : 0x7C00; return r; }
    int e = ilogbl(s); if (e < -14) e = -14;
    hbegin(m); long double q = rintl(ldexpl(s, 10 - e)); hend();
    long double v = ldexpl(q, e - 10);
    if (fabsl(v) > 65504.0L) {
        int up = (m == FE_TONEAREST) || (m == FE_UPWARD && s > 0) || (m == FE_DOWNWARD && s < 0);
        r.v.m = (s < 0 ? 0x8000 : 0) | (up ? 0x7C00 : 0x7BFF); r.f = FE_OVERFLOW | FE_INEXACT; return r;
    }
    _Float16 h = (_Float16)(float)v; uint16_t hb; memcpy(&hb, &h, 2); r.v.m = hb;
    if (v != s) {
        r.f = FE_INEXACT;
        int e2 = ilogbl(s); hbegin(m); long double q2 = rintl(ldexpl(s, 10 - e2)); hend();
        if (fabsl(ldexpl(q2, e2 - 10)) < 0x1p-14L) r.f |= FE_UNDERFLOW;
    }
    return r;
}
static void run_conv(void) {
    X sp[64]; int ns = specials(sp); X z = {0, 0};
    for (int t = 0; t < ns + 4000; t++) {
        X a = t < ns ? sp[t] : rndx(); volatile long double x = L(a);
        for (int mi = 0; mi < 4; mi++) {
            int m = MODES[mi]; R ref, lib;
            /* f80 -> f64, f32 */
            hbegin(m); volatile double d = (double)x; ref.f = hend() & ~2u; uint64_t db; memcpy(&db, (const void *)&d, 8);
            if (isnan(d)) db = canon_nan(a) && !noncanon(a) ? ((a.e & 0x8000ull) << 48) | 0x7FF8000000000000ull | ((a.m << 1) >> 12) : 0xFFF8000000000000ull;
            ref.v = (X){db, 0};
            lib.v = (X){0, 0}; double ld = cqsf_fptrunc_f80_to_f64_m(x, m); memcpy(&lib.v.m, &ld, 8); lib.f = cqsf_fptrunc_f80_to_f64_x(x, m);
            chkx("fptrunc_f80_to_f64_rm", m, a, z, lib, ref, 1);
            hbegin(m); volatile float f = (float)x; ref.f = hend() & ~2u; uint32_t fb; memcpy(&fb, (const void *)&f, 4);
            if (isnan(f)) fb = canon_nan(a) && !noncanon(a) ? (uint32_t)((a.e & 0x8000u) << 16) | 0x7FC00000u | (uint32_t)((a.m << 1) >> 41) : 0xFFC00000u;
            ref.v = (X){fb, 0};
            float lf = cqsf_fptrunc_f80_to_f32_m(x, m); uint32_t lfb; memcpy(&lfb, &lf, 4); lib.v = (X){lfb, 0}; lib.f = cqsf_fptrunc_f80_to_f32_x(x, m);
            chkx("fptrunc_f80_to_f32_rm", m, a, z, lib, ref, 1);
            /* f80 -> f16: no x87 instruction; the exact value rounded here, NaN by CR §2 */
            if (noncanon(a)) { ref.v = (X){0xFE00, 0}; ref.f = FE_INVALID; }
            else if (isnanx(a)) { ref.v = (X){((a.e & 0x8000u)) | 0x7E00u | (uint16_t)((a.m << 1) >> 54), 0}; ref.f = issnanx(a) ? FE_INVALID : 0; }
            else { X c = a; if (!(c.e & 0x7FFF) && (c.m >> 63)) c.e |= 1;   /* a pseudo-denormal reads as a denormal */
                   ref = ld_to_f16(L(c), m); }
            _Float16 lh = cqsf_fptrunc_f80_to_f16_m(x, m); uint16_t lhb; memcpy(&lhb, &lh, 2); lib.v = (X){lhb, 0}; lib.f = cqsf_fptrunc_f80_to_f16_x(x, m);
            chkx("fptrunc_f80_to_f16_rm", m, a, z, lib, ref, 1);
        }
        /* f80 -> int: values the -O1 code (host_f80.c), flags the host's strict conversion */
        u64 v[8]; hv_fptoint_f80(x, v);
        unsigned f[8];
        hbegin(FE_TONEAREST); volatile int8_t h0 = (int8_t)x; f[0] = hend();
        hbegin(FE_TONEAREST); volatile int16_t h1 = (int16_t)x; f[1] = hend();
        hbegin(FE_TONEAREST); volatile int32_t h2 = (int32_t)x; f[2] = hend();
        hbegin(FE_TONEAREST); volatile int64_t h3 = (int64_t)x; f[3] = hend();
        hbegin(FE_TONEAREST); volatile uint8_t h4 = (uint8_t)x; f[4] = hend();
        hbegin(FE_TONEAREST); volatile uint16_t h5 = (uint16_t)x; f[5] = hend();
        hbegin(FE_TONEAREST); volatile uint32_t h6 = (uint32_t)x; f[6] = hend();
        hbegin(FE_TONEAREST); volatile uint64_t h7 = (uint64_t)x; f[7] = hend();
        (void)h0; (void)h1; (void)h2; (void)h3; (void)h4; (void)h5; (void)h6; (void)h7;
        u64 lv[8] = {(uint8_t)cqsf_fptosi_f80_to_i8(x), (uint16_t)cqsf_fptosi_f80_to_i16(x), (uint32_t)cqsf_fptosi_f80_to_i32(x),
                     (u64)cqsf_fptosi_f80_to_i64(x), cqsf_fptoui_f80_to_i8(x), cqsf_fptoui_f80_to_i16(x), cqsf_fptoui_f80_to_i32(x),
                     cqsf_fptoui_f80_to_i64(x)};
        unsigned lfl[8] = {cqsf_fptosi_f80_to_i8_x(x), cqsf_fptosi_f80_to_i16_x(x), cqsf_fptosi_f80_to_i32_x(x), cqsf_fptosi_f80_to_i64_x(x),
                           cqsf_fptoui_f80_to_i8_x(x), cqsf_fptoui_f80_to_i16_x(x), cqsf_fptoui_f80_to_i32_x(x), cqsf_fptoui_f80_to_i64_x(x)};
        const char *nm[8] = {"fptosi_f80_to_i8", "fptosi_f80_to_i16", "fptosi_f80_to_i32", "fptosi_f80_to_i64",
                             "fptoui_f80_to_i8", "fptoui_f80_to_i16", "fptoui_f80_to_i32", "fptoui_f80_to_i64"};
        for (int k = 0; k < 8; k++) chk(nm[k], 0, a, z, lv[k] != v[k], lfl[k] != (f[k] & ~2u), lv[k], v[k], lfl[k], f[k] & ~2u);
    }
    /* to f80 (exact) */
    for (int t = 0; t < 4000; t++) {
        u64 r = rnd() >> (rnd() % 64); int64_t s = (int64_t)r; uint16_t hb = (uint16_t)rnd(); uint32_t fb = (uint32_t)rnd();
        _Float16 h; memcpy(&h, &hb, 2); float f; memcpy(&f, &fb, 4); double d; memcpy(&d, &r, 8);
        X a = {r, 0};
        hbegin(FE_TONEAREST); volatile long double e1 = (long double)(float)h; unsigned g1 = hend() & ~2u;
        hbegin(FE_TONEAREST); volatile long double e2 = (long double)f; unsigned g2 = hend() & ~2u;
        hbegin(FE_TONEAREST); volatile long double e3 = (long double)d; unsigned g3 = hend() & ~2u;
        X w1 = Xb(e1), w2 = Xb(e2), w3 = Xb(e3);
        X l1 = Xb(cqsf_fpext_f16_to_f80(h)), l2 = Xb(cqsf_fpext_f32_to_f80(f)), l3 = Xb(cqsf_fpext_f64_to_f80(d));
        chk("fpext_f16_to_f80", 0, a, a, !xeq(l1, w1), cqsf_fpext_f16_to_f80_x(h) != g1, l1.m, w1.m, cqsf_fpext_f16_to_f80_x(h), g1);
        chk("fpext_f32_to_f80", 0, a, a, !xeq(l2, w2), cqsf_fpext_f32_to_f80_x(f) != g2, l2.m, w2.m, cqsf_fpext_f32_to_f80_x(f), g2);
        chk("fpext_f64_to_f80", 0, a, a, !xeq(l3, w3), cqsf_fpext_f64_to_f80_x(d) != g3, l3.m, w3.m, cqsf_fpext_f64_to_f80_x(d), g3);
        X ws = Xb((long double)s), wu = Xb((long double)r);
        X ls = Xb(cqsf_sitofp_i64_to_f80(s)), lu = Xb(cqsf_uitofp_i64_to_f80(r));
        X l8 = Xb(cqsf_sitofp_i8_to_f80((int8_t)s)), w8 = Xb((long double)(int8_t)s);
        chk("sitofp_i64_to_f80", 0, a, a, !xeq(ls, ws), cqsf_sitofp_i64_to_f80_x(s, 0) != 0, ls.m, ws.m, 0, 0);
        chk("uitofp_i64_to_f80", 0, a, a, !xeq(lu, wu), cqsf_uitofp_i64_to_f80_x(r, 0) != 0, lu.m, wu.m, 0, 0);
        chk("sitofp_i8_to_f80", 0, a, a, !xeq(l8, w8), 0, l8.m, w8.m, 0, 0);
    }
}

int main(void) {
    Op ops[] = {OP2(fadd, h_add, 1), OP2(fsub, h_sub, 1), OP2(fmul, h_mul, 1), OP2(fdiv, h_div, 1), OP2(frem, h_rem, 1),
                OP1M(sqrt, h_sqrt), OP1M(rint, h_rint), OP1(floor, h_floor), OP1(ceil, h_ceil), OP1(trunc, h_trunc), OP1(round, h_round)};
    for (unsigned i = 0; i < sizeof ops / sizeof ops[0]; i++) run_op(&ops[i]);
    so("frem_f80")->note = so("frem_f80_rm")->note = "value: libm fmodl; NaN and flags by CR §2";
    so("round_f80")->note = "reference: libm roundl";
    run_misc();
    run_conv();
    so("fptrunc_f80_to_f16_rm")->note = "reference: the exact value rounded here (no x87 f16 instruction)";
    long n = 0, bv = 0, bf = 0;
    printf("\n%-28s %9s %8s %8s  %s\n", "operation", "cases", "badval", "badflag", "note");
    for (int i = 0; i < nst; i++) {
        n += st[i].n; bv += st[i].badv; bf += st[i].badf;
        printf("%-28s %9ld %8ld %8ld  %s\n", st[i].op, st[i].n, st[i].badv, st[i].badf, st[i].note ? st[i].note : "");
    }
    printf("\nTOTAL f80 cases %ld, value mismatches %ld, flag mismatches %ld, operations %d\n", n, bv, bf, nst);
    return (bv || bf) ? 1 : 0;
}
