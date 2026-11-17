/* selftest_bf16.c: the bf16 arithmetic, compare and rounding roots (cqsf.h, "bf16 arithmetic") against an
 * independent reference and the host, bit for bit, in the four modes, with the flags.
 * Build and run: softfloat/test/run_selftest.sh bf16.
 *
 * CR §1.1 gives bf16 the rounding and NaN rules of the IEEE widths: one correct rounding in the mode.
 * References:
 *   + - * / sqrt fma: the exact result on the host's x87 rounded toward zero with the last bit set when
 *     inexact (round to odd at 64 bits), then to f32 the same way (odd at 24 bits), then rounded to bf16
 *     in the mode by ref_bf16 here: one correct rounding (64, 24 >= 8 + 2). INVALID and DIVBYZERO from
 *     the x87; INEXACT from any step; OVERFLOW, UNDERFLOW (tininess after rounding) at bf16. An exact zero
 *     sum is redone in the mode for its sign. NaN results: the CR §2 row (the first NaN operand quieted,
 *     0xFFC0 for an invalid operation; fma: INVALID only for an sNaN, as the other widths);
 *   frem: fmodl (exact), NaN and flags by CR §2 as in selftest.c;
 *   floor ceil trunc rint round, compares: the host's f32 operation on the exact extension (FENV_ACCESS),
 *     the result narrowed exactly; fmax/fmin: the CR §2 row.
 *   Also, in round-to-nearest, against the host's own -O1 code for __bf16 (host_bf16.c: f32 operation, then
 *   __truncsfbf2): + - * / sqrt floor ceil trunc rint and < bit for bit; fma is counted apart (the host's
 *   f32 fma then truncation rounds twice; CR §1.1 asks for one rounding). */
#pragma STDC FENV_ACCESS ON
#include <fenv.h>
#include <inttypes.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cqsf_roots.h"

typedef uint64_t u64;
#define FE_ALL (FE_INVALID | FE_DIVBYZERO | FE_OVERFLOW | FE_UNDERFLOW | FE_INEXACT)
static const int MODES[4] = {FE_TONEAREST, FE_DOWNWARD, FE_UPWARD, FE_TOWARDZERO};
static void hbegin(int m) { fesetround(m); feclearexcept(FE_ALL_EXCEPT); }
static unsigned hend(void) { unsigned f = (unsigned)fetestexcept(FE_ALL); fesetround(FE_TONEAREST); return f; }

/* host_bf16.c (no FENV_ACCESS): the host's __bf16 code, and calls of the roots that take __bf16 */
u64 hb_add(u64, u64); u64 hb_sub(u64, u64); u64 hb_mul(u64, u64); u64 hb_div(u64, u64); u64 hb_sqrt(u64); u64 hb_fma(u64, u64, u64);
u64 hb_floor(u64); u64 hb_ceil(u64); u64 hb_trunc(u64); u64 hb_rint(u64); u64 hb_lt(u64, u64);
u64 lbc(void *f, int ar, int hm, u64 a, u64 b, u64 c, uint32_t m);
uint32_t lbx(void *f, int ar, int hm, u64 a, u64 b, u64 c, uint32_t m);
bool lbcmp(void *f, u64 a, u64 b);

static float F(u64 b) { uint32_t u = (uint32_t)(b & 0xFFFF) << 16; float f; memcpy(&f, &u, 4); return f; }
static uint32_t Fb(float f) { uint32_t u; memcpy(&u, &f, 4); return u; }
static int isnanb(u64 a) { return (a & 0x7F80) == 0x7F80 && (a & 0x7F); }
static int issnanb(u64 a) { return isnanb(a) && !(a & 0x40); }

static u64 rng = 0xBE5466CF34E90C6Cu;
static u64 rnd(void) { rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17; return rng; }
static int specials(u64 *o) {
    static const u64 b[] = {0, 1, 0x7F, 0x80, 0x3F80, 0x3F81, 0x3FC0, 0x4000, 0x40C0, 0x7F7F, 0x7F00, 0x7F80, 0x7FC0, 0x7FC5,
                            0x7F81, 0x7FA3, 0x3F40, 0x3F00, 0x4300, 0x4301, 0x0040, 0x007E, 0x0081, 0x3F7F, 0x4B00, 0x0001};
    int n = 0;
    for (unsigned i = 0; i < sizeof b / sizeof b[0]; i++) { o[n++] = b[i]; o[n++] = b[i] | 0x8000; }
    return n;
}
static u64 rndv(void) {
    u64 r = rnd();
    if (r & 1) return (r >> 8) & 0xFFFF;
    return ((rnd() & 1) ? 0x8000 : 0) | ((u64)(127 + (int)(rnd() % 61) - 30) << 7) | (rnd() & 0x7F);
}

/* ---- stats ---- */
typedef struct { const char *op; long n, badv, badf, nh, bh; const char *note; } Stat;
static Stat st[256]; static int nst;
static Stat *so(const char *op) { for (int i = 0; i < nst; i++) if (!strcmp(st[i].op, op)) return &st[i]; st[nst].op = strdup(op); return &st[nst++]; }
static void chk(const char *op, int m, const u64 *in, int nin, u64 lv, u64 rv, unsigned lf, unsigned rf, int cmpf) {
    Stat *s = so(op); s->n++;
    int bv = lv != rv, bf = cmpf && lf != rf;
    s->badv += bv; s->badf += bf;
    if ((bv || bf) && s->badv + s->badf <= 3) {
        printf("MISMATCH %-20s mode %4d in", op, m);
        for (int i = 0; i < nin; i++) printf(" %#06" PRIx64, in[i]);
        printf(": lib %#06" PRIx64 " f%02x ref %#06" PRIx64 " f%02x\n", lv, lf, rv, rf);
    }
}
static void hostchk(const char *op, const u64 *in, int nin, u64 ref, u64 host) {
    Stat *s = so(op); s->nh++;
    if (ref != host) { s->bh++; if (s->bh <= 3) { printf("HOST %-20s in", op); for (int i = 0; i < nin; i++) printf(" %#06" PRIx64, in[i]); printf(": ref %#06" PRIx64 " host %#06" PRIx64 "\n", ref, host); } }
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
        if (e == 0) {
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

enum { ADD, SUB, MUL, DIV, SQRT, FMA };
static long double x87op(int op, long double x, long double y, long double z) {
    volatile long double a = x, b = y, c = z, r;
    switch (op) {
    case ADD: r = a + b; break; case SUB: r = a - b; break; case MUL: r = a * b; break; case DIV: r = a / b; break;
    case SQRT: r = sqrtl(a); break; default: r = a * b + c; break;   /* a*b is exact in 64 bits (8 x 8) */
    }
    return r;
}
static u64 ref_ar(int op, const u64 *in, int ar, int m, unsigned *fl) {
    *fl = 0;
    int anan = 0;
    for (int i = 0; i < ar; i++) anan |= isnanb(in[i]);
    if (anan) {
        for (int i = 0; i < ar; i++) if (issnanb(in[i])) *fl = FE_INVALID;
        for (int i = 0; i < ar; i++) if (isnanb(in[i])) return in[i] | 0x40;
    }
    long double x = F(in[0]), y = ar > 1 ? F(in[1]) : 0, z = ar > 2 ? F(in[2]) : 0;
    hbegin(FE_TOWARDZERO); long double r = x87op(op, x, y, z); unsigned f1 = hend() & ~2u;
    if (f1 & FE_INVALID) { *fl = FE_INVALID; return 0xFFC0; }
    if (r == 0 && !(f1 & FE_INEXACT)) { hbegin(m); r = x87op(op, x, y, z); hend(); }   /* the sign of an exact zero */
    if (f1 & FE_INEXACT) { u64 sig; memcpy(&sig, &r, 8); sig |= 1; memcpy(&r, &sig, 8); }   /* odd at 64 bits */
    hbegin(FE_TOWARDZERO); volatile float fv = (float)r; unsigned f2 = hend() & ~2u;
    uint32_t fb = Fb(fv);
    if ((f2 & FE_INEXACT) && (fb & 0x7F800000) != 0x7F800000) fb |= 1;               /* odd at 24 bits */
    unsigned f3 = 0; u64 v = ref_bf16(fb, m, &f3);
    *fl = (f1 & (FE_DIVBYZERO | FE_INEXACT)) | (f2 & (FE_OVERFLOW | FE_INEXACT)) | f3;
    return v;
}

typedef struct { const char *n; int op, ar, hm; void *p, *pm, *px; u64 (*host)(); } Ar;
static void run_ar(const Ar *o) {
    u64 sp[64]; int ns = specials(sp); char nr[48]; snprintf(nr, sizeof nr, "%s_rm", o->n);
    long tot = o->ar == 1 ? 65536 : o->ar == 2 ? (long)ns * ns + 60000 : 20L * 20 * 20 + 60000;
    for (long t = 0; t < tot; t++) {
        u64 in[3] = {0, 0, 0};
        if (o->ar == 1) in[0] = (u64)t;
        else if (o->ar == 2) { if (t < (long)ns * ns) { in[0] = sp[t / ns]; in[1] = sp[t % ns]; } else { in[0] = rndv(); in[1] = rndv(); } }
        else if (t < 8000) { in[0] = sp[(t / 400) * 2 % ns]; in[1] = sp[((t / 20) % 20) * 2 % ns + (t & 1)]; in[2] = sp[(t % 20) * 2 % ns + ((t >> 1) & 1)]; }
        else {
            in[0] = rndv(); in[1] = rndv(); in[2] = rndv();
            if (t & 1) {   /* hard cases: c near -(a*b), cancellation and ties */
                float p = F(in[0]) * F(in[1]); in[2] = ((Fb(-p) >> 16) + (rnd() % 5) - 2) & 0xFFFF;
            }
        }
        for (int mi = 0; mi < 4; mi++) {
            int m = MODES[mi]; unsigned rf; u64 rv = ref_ar(o->op, in, o->ar, m, &rf);
            if (mi == 0) {
                u64 lv = lbc(o->p, o->ar, 0, in[0], in[1], in[2], 0); unsigned lf = lbx(o->px, o->ar, 1, in[0], in[1], in[2], 0);
                chk(o->n, m, in, o->ar, lv, rv, lf, rf, 1);
                u64 hv = o->ar == 1 ? o->host(in[0]) : o->ar == 2 ? o->host(in[0], in[1]) : o->host(in[0], in[1], in[2]);
                if (isnanb(hv) && isnanb(rv) && o->ar > 1) hv = rv;   /* two-NaN choice: the CR row (host: register order) */
                hostchk(o->n, in, o->ar, rv, hv);
            }
            u64 lv = lbc(o->pm, o->ar, 1, in[0], in[1], in[2], (uint32_t)m); unsigned lf = lbx(o->px, o->ar, 1, in[0], in[1], in[2], (uint32_t)m);
            chk(nr, m, in, o->ar, lv, rv, lf, rf, 1);
        }
    }
}

/* frem: fmod, exact; NaN and flags by CR §2 */
static void run_frem(void) {
    u64 sp[64]; int ns = specials(sp);
    for (long t = 0; t < (long)ns * ns + 60000; t++) {
        u64 in[2];
        if (t < (long)ns * ns) { in[0] = sp[t / ns]; in[1] = sp[t % ns]; } else { in[0] = rndv(); in[1] = rndv(); }
        u64 rv; unsigned rf;
        int an = isnanb(in[0]) || isnanb(in[1]);
        int inf = (in[0] & 0x7FFF) == 0x7F80, zero = !(in[1] & 0x7FFF);
        rf = (issnanb(in[0]) || issnanb(in[1]) || (!an && (inf || zero))) ? FE_INVALID : 0;
        if (an) rv = (isnanb(in[0]) ? in[0] : in[1]) | 0x40;
        else if (inf || zero) rv = 0xFFC0;
        else { float r = (float)fmodl(F(in[0]), F(in[1])); rv = Fb(r) >> 16; }
        for (int mi = 0; mi < 4; mi++) {
            int m = MODES[mi];
            if (mi == 0) chk("frem_bf16", m, in, 2, lbc((void *)cqsf_frem_bf16, 2, 0, in[0], in[1], 0, 0), rv,
                             lbx((void *)cqsf_frem_bf16_x, 2, 1, in[0], in[1], 0, 0), rf, 1);
            chk("frem_bf16_rm", m, in, 2, lbc((void *)cqsf_frem_bf16_m, 2, 1, in[0], in[1], 0, (uint32_t)m), rv,
                lbx((void *)cqsf_frem_bf16_x, 2, 1, in[0], in[1], 0, (uint32_t)m), rf, 1);
        }
    }
    so("frem_bf16")->note = so("frem_bf16_rm")->note = "reference: fmodl; NaN and flags by CR §2";
}

/* the rounding ops: the host's f32 operation on the extension, narrowed (exact) */
static void run_rnd(void) {
    static const char *nm[5] = {"floor_bf16", "ceil_bf16", "trunc_bf16", "round_bf16", "rint_bf16"};
    void *p[5] = {(void *)cqsf_floor_bf16, (void *)cqsf_ceil_bf16, (void *)cqsf_trunc_bf16, (void *)cqsf_round_bf16, (void *)cqsf_rint_bf16};
    void *px[5] = {(void *)cqsf_floor_bf16_x, (void *)cqsf_ceil_bf16_x, (void *)cqsf_trunc_bf16_x, (void *)cqsf_round_bf16_x, (void *)cqsf_rint_bf16_x};
    u64 (*hf[5])(u64) = {hb_floor, hb_ceil, hb_trunc, 0, hb_rint};
    for (int k = 0; k < 5; k++)
        for (u64 a = 0; a < 65536; a++)
            for (int mi = 0; mi < (k == 4 ? 4 : 1); mi++) {
                int m = MODES[mi]; volatile float x = F(a); float r;
                hbegin(m);
                switch (k) { case 0: r = __builtin_floorf(x); break; case 1: r = __builtin_ceilf(x); break; case 2: r = __builtin_truncf(x); break;
                             case 3: r = roundf(x); break; default: r = __builtin_rintf(x); break; }
                unsigned rf = hend() & ~2u;
                if (k == 3 && issnanb(a)) rf = FE_INVALID;   /* libm roundf: IEEE INVALID for an sNaN (as selftest.c's round) */
                u64 rv = (Fb(r) >> 16) | (isnan(r) ? 0x40 : 0), in[1] = {a};
                if (mi == 0) { chk(nm[k], m, in, 1, lbc(p[k], 1, 0, a, 0, 0, 0), rv, lbx(px[k], 1, k == 4, a, 0, 0, 0), rf, 1);
                               if (hf[k]) hostchk(nm[k], in, 1, rv, isnanb(hf[k](a)) && isnanb(rv) ? rv : hf[k](a)); }
                if (k == 4) chk("rint_bf16_rm", m, in, 1, lbc((void *)cqsf_rint_bf16_m, 1, 1, a, 0, 0, (uint32_t)m), rv,
                                lbx(px[k], 1, 1, a, 0, 0, (uint32_t)m), rf, 1);
            }
    so("round_bf16")->note = "reference: libm roundf on the extension";
}

/* compares, fmax/fmin */
static void run_cmp(void) {
    static const char *pn[14] = {"oeq", "ogt", "oge", "olt", "ole", "one", "ord", "ueq", "ugt", "uge", "ult", "ule", "une", "uno"};
    void *cp[14] = {(void *)cqsf_fcmp_oeq_bf16, (void *)cqsf_fcmp_ogt_bf16, (void *)cqsf_fcmp_oge_bf16, (void *)cqsf_fcmp_olt_bf16,
        (void *)cqsf_fcmp_ole_bf16, (void *)cqsf_fcmp_one_bf16, (void *)cqsf_fcmp_ord_bf16, (void *)cqsf_fcmp_ueq_bf16,
        (void *)cqsf_fcmp_ugt_bf16, (void *)cqsf_fcmp_uge_bf16, (void *)cqsf_fcmp_ult_bf16, (void *)cqsf_fcmp_ule_bf16,
        (void *)cqsf_fcmp_une_bf16, (void *)cqsf_fcmp_uno_bf16};
    u64 sp[64]; int ns = specials(sp); char nm[40];
    for (long t = 0; t < (long)ns * ns + 60000; t++) {
        u64 in[2];
        if (t < (long)ns * ns) { in[0] = sp[t / ns]; in[1] = sp[t % ns]; } else { in[0] = rndv(); in[1] = rndv(); }
        volatile float x = F(in[0]), y = F(in[1]);
        int un = __builtin_isunordered(x, y), lt = __builtin_isless(x, y), gt = __builtin_isgreater(x, y), eq = !un && !lt && !gt;
        int want[14] = {eq, gt, gt || eq, lt, lt || eq, lt || gt, !un, un || eq, un || gt, un || gt || eq, un || lt, un || lt || eq, !eq, un};
        for (int k = 0; k < 14; k++) { snprintf(nm, sizeof nm, "fcmp_%s_bf16", pn[k]); chk(nm, 0, in, 2, lbcmp(cp[k], in[0], in[1]), (u64)want[k], 0, 0, 0); }
        hostchk("fcmp_olt_bf16", in, 2, (u64)lt, hb_lt(in[0], in[1]));
        hbegin(FE_TONEAREST); volatile int r1 = (x == y); unsigned fq = hend() & ~2u;
        hbegin(FE_TONEAREST); volatile int r2 = (x <= y); unsigned fs = hend() & ~2u; (void)r1; (void)r2;
        chk("fcmp_*_bf16_exc", 0, in, 2, 0, 0, lbx((void *)cqsf_fcmpq_bf16_x, 2, 0, in[0], in[1], 0, 0), fq, 1);
        chk("fcmps_*_bf16_exc", 0, in, 2, 0, 0, lbx((void *)cqsf_fcmps_bf16_x, 2, 0, in[0], in[1], 0, 0), fs, 1);
        for (int mn = 0; mn < 2; mn++) {   /* CR §2 row; INVALID for an sNaN */
            u64 w = isnanb(in[0]) ? in[1] : isnanb(in[1]) ? in[0] : ((mn ? y < x : y > x) ? in[1] : in[0]);
            unsigned wf = (issnanb(in[0]) || issnanb(in[1])) ? FE_INVALID : 0;
            void *f = mn ? (void *)cqsf_fmin_bf16 : (void *)cqsf_fmax_bf16, *fx = mn ? (void *)cqsf_fmin_bf16_x : (void *)cqsf_fmax_bf16_x;
            chk(mn ? "fmin_bf16" : "fmax_bf16", 0, in, 2, lbc(f, 2, 0, in[0], in[1], 0, 0), w, lbx(fx, 2, 0, in[0], in[1], 0, 0), wf, 1);
        }
    }
    so("fmax_bf16")->note = so("fmin_bf16")->note = "reference: the CR §2 row";
}

int main(void) {
    Ar ops[] = {
        {"fadd_bf16", ADD, 2, 1, (void *)cqsf_fadd_bf16, (void *)cqsf_fadd_bf16_m, (void *)cqsf_fadd_bf16_x, (u64 (*)())hb_add},
        {"fsub_bf16", SUB, 2, 1, (void *)cqsf_fsub_bf16, (void *)cqsf_fsub_bf16_m, (void *)cqsf_fsub_bf16_x, (u64 (*)())hb_sub},
        {"fmul_bf16", MUL, 2, 1, (void *)cqsf_fmul_bf16, (void *)cqsf_fmul_bf16_m, (void *)cqsf_fmul_bf16_x, (u64 (*)())hb_mul},
        {"fdiv_bf16", DIV, 2, 1, (void *)cqsf_fdiv_bf16, (void *)cqsf_fdiv_bf16_m, (void *)cqsf_fdiv_bf16_x, (u64 (*)())hb_div},
        {"sqrt_bf16", SQRT, 1, 1, (void *)cqsf_sqrt_bf16, (void *)cqsf_sqrt_bf16_m, (void *)cqsf_sqrt_bf16_x, (u64 (*)())hb_sqrt},
        {"fma_bf16", FMA, 3, 1, (void *)cqsf_fma_bf16, (void *)cqsf_fma_bf16_m, (void *)cqsf_fma_bf16_x, (u64 (*)())hb_fma},
    };
    for (unsigned i = 0; i < sizeof ops / sizeof ops[0]; i++) run_ar(&ops[i]);
    so("fma_bf16")->note = "vs host: clang's f32 fma then __truncsfbf2 rounds twice; CR §1.1 asks for one rounding";
    run_frem(); run_rnd(); run_cmp();
    long n = 0, bv = 0, bf = 0, nh = 0, bh = 0, bhf = 0;
    printf("\n%-22s %8s %7s %7s %8s %7s  %s\n", "operation", "cases", "badval", "badflag", "vs host", "differ", "note");
    for (int i = 0; i < nst; i++) {
        Stat *s = &st[i]; n += s->n; bv += s->badv; bf += s->badf; nh += s->nh;
        if (!strcmp(s->op, "fma_bf16")) bhf += s->bh; else bh += s->bh;
        printf("%-22s %8ld %7ld %7ld %8ld %7ld  %s\n", s->op, s->n, s->badv, s->badf, s->nh, s->bh, s->note ? s->note : "");
    }
    printf("\nTOTAL bf16 cases %ld, value mismatches %ld, flag mismatches %ld, operations %d; RNE values against the host's "
           "own code: %ld compared, %ld differ (fma, double rounding on the host: %ld)\n", n, bv, bf, nst, nh, bh, bhf);
    return (bv || bf || bh) ? 1 : 0;
}
