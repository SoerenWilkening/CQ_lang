/* slice_branchless_cosl.c — bd 20xt.8 Inc 1 / the ld80 (x86_fp80) branchless-leaf
   e2e twin of tools/library_coverage/branchless/cosl.c. An AUTHORED branchless
   soft-cosl is inlined here as `bcosl`, so clang -O1 inlines it to stock
   reversible OPCODES and the taint pass lowers those (no per-fn cq_template_cosl).
   Owner-approved 2026-07-23 (recipe carve-out): a DISJOINT hybrid/authored-leaf
   provenance, NEVER quoted alongside the real-openlibm goldens; verification is
   e2e-golden-only and the census cell cosl.f80 stays declined (NO census delta).

   openlibm's cosl reduces x with the full __kernel_rem_pio2 Payne–Hanek reduction
   (Bennett MUX-EXCH, ROADMAP 7.5 post-freeze); see slice_branchless_sinl.c for the
   full derivation. cos = sin(x + π/2): the SAME register-only 2-term Cody–Waite
   reduction and the SAME k_sinl/k_cosl kernels, differing only by the +1 quadrant
   offset (fn+1). Both kernels are computed unconditionally and blended by the
   UNCONDITIONAL weighted expression sgn·(useS·S+(1−useS)·C) with CONSTANT-operand
   fp selects (every comparison a `<` against a constant — speculatable, never
   branch-ified; the kjd1 fp-DATA select controlled-copy merge at f80 →
   cqrt_copy_f80_controlled; a libm body mints no Rz/Ry). The reduced arg is
   clamped yc=fmaxl(-π/4,fminl(y,π/4)) with the NaN-suppressing keep-set
   fminl/fmaxl, so cos is FINITE for every long double (±∞/NaN → finite). It
   exercises the f80 fp-select controlled-copy merge plus the rintl/floorl/fminl/
   fmaxl keep-set leaves (cq-lowering rewrites @llvm.{rint,floor,minnum,maxnum}.f80
   to cq_template_*_f80 before codegen — pure-register, no Shadow/i80/memcpy).

   The corpus twin is tools/library_coverage/branchless/cosl.c (same body) — keep
   the two textually in sync. */
static long double bcosl(long double x) {
    const long double invpio2 = 6.36619772367581343076e-01L;
    const double      pio2_1  = 1.57079632679597125389e+00;
    const long double pio2_1t = -1.07463465549719416346e-12L;
    const long double PIO4    = 0.78539816339744830962L;
    const long double S1 = -0.166666666666666666671L;
    const double      S2 =  0.0083333333333333332,       S3 = -0.00019841269841269427,
                      S4 =  0.0000027557319223597490,    S5 = -0.000000025052108218074604,
                      S6 =  1.6059006598854211e-10,       S7 = -7.6429779983024564e-13,
                      S8 =  2.6174587166648325e-15;
    const long double C1 =  0.0416666666666666666136L;
    const double      C2 = -0.0013888888888888874,       C3 =  0.000024801587301571716,
                      C4 = -0.00000027557319215507120,   C5 =  0.0000000020876754400407278,
                      C6 = -1.1470297442401303e-11,       C7 =  4.7383039476436467e-14;

    long double fn = __builtin_rintl(x * invpio2);
    long double y  = (x - fn * pio2_1) - fn * pio2_1t;
    long double yc = __builtin_fmaxl(-PIO4, __builtin_fminl(y, PIO4));

    long double z  = yc * yc;
    long double rs = S2 + z*(S3 + z*(S4 + z*(S5 + z*(S6 + z*(S7 + z*S8)))));
    long double v  = z * yc;
    long double S  = yc + v*(S1 + z*rs);
    long double rc = z*(C1 + z*(C2 + z*(C3 + z*(C4 + z*(C5 + z*(C6 + z*C7))))));
    long double hz = 0.5L * z, wc = 1.0L - hz;
    long double C  = wc + (((1.0L - wc) - hz) + z * rc);

    long double fq   = fn + 1.0L;
    long double qf   = fq - 4.0L * __builtin_floorl(fq * 0.25L);
    long double half = __builtin_floorl(qf * 0.5L);
    long double par  = qf - 2.0L * half;
    long double useS = (par  < 0.5L) ? 1.0L : 0.0L;
    long double sgn  = (half < 0.5L) ? 1.0L : -1.0L;
    long double mag  = useS * S + (1.0L - useS) * C;
    return sgn * mag;
}
long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(bcosl(q));
}
int main(void) { (void) slice(); return 0; }
