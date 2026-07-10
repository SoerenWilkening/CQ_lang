/* branchless/erf.c — bd 3c6m.27 (libm L2-closure): the AUTHORED branchless erf
   body the census injects for `erf` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model). This
   file SHADOWS openlibm's branchy s_erf.c in the census symbol index.

   openlibm's erf/erfc select one of FIVE |x| segments with a nested `if(ix<…)`
   ladder plus an exp-based asymptotic — the deepest branchy libm body in the
   corpus (the L2/L6 blocker at s_erf.c:238, the `__ieee754_exp` call). This body
   keeps openlibm's OWN minimax coefficients but renders the range dispatch as the
   Cephes/atan pattern — CONSTANT-operand fp SELECTS producing 0/1 regime WEIGHTS
   that feed an UNCONDITIONAL weighted sum. Because every regime formula is
   evaluated unconditionally on a CLAMPED argument (all three finite for every
   finite x) and combined by arithmetic — never a value-arm select — clang -O1
   cannot branch-ify the expensive exp regime onto one arm (the tainted-control
   decline this body exists to avoid), and 0*finite = 0 keeps the blend exact
   (exactly one weight is 1; the branchless equivalent of openlibm's dispatch).

   Three regimes for t = |x| (openlibm's own, on clamped arguments):
     R1  t < 0.84375           erf = t + t*(P(z)/Q(z)),   z = t^2
     R2  0.84375 <= t < 1.25   erf = erx + P1(s)/Q1(s),   s = t-1
     R3+ t >= 1.25             erf = 1 - erfc(t),
         erfc(t) = exp(-z^2-0.5625)*exp((z-t)(z+t)+R/S)/t,  z = t low-word-cleared,
         R/S the (t<1/0.35 ? Ra/Sa : Rb/Sb) asymptotic rational in w = 1/t^2.
   erf is odd; the sign rides a final copysign. The exp is evaluated the accurate
   way — the L2-closure spine — via the `expm1` leaf: exp(y) = 2^n*(expm1(r)+1),
   r = y - n*ln2 in [-ln2/2, ln2/2] (near 0, where expm1 is <2 ulp and the +1
   never cancels since expm1(r) in [-0.293,0.414]); the 2^n scale is SPLIT into
   two half-exponents so a large-negative y underflows cleanly to 0 (the erfc
   tail) instead of a bogus exponent field. `expm1` resolves by the census
   closure-link to the authored branchless/expm1.c (indexed first) and inlines,
   exactly as tanh/sinh/cosh call expm1. fabs/fmin/fmax/copysign are the hardware
   keep-set leaves; the two INSERT/EXTRACT bitcasts (the low-word clear and the
   2^n scale) lower as injected opcodes (p119.7). NO tables, NO control flow.

   The e2e golden twin is tests/e2e/slice_branchless_erf.c (same body, with expm1
   inlined as the static `bexpm1` helper) — keep the three textually in sync
   (bexpm1 == branchless/expm1.c; bexp/erf identical).

   Domain: finite x. erf saturates to +-1 by |x|~6. A faithful branchless erf over
   openlibm's own coefficients (spot-checked to a few ulp vs a high-precision
   reference); the runtime is trace-only, so classical ulp is a sanity check, not a
   gate. +-0 -> +-0 (copysign preserves the signed zero). te is clamped to
   [1.25, 30] so z^2 never overflows: erf(x)=+-1 exactly for all |x| in [6, DBL_MAX].
   inf/NaN are UNSPECIFIED (the branchy special cases this body omits); the te-clamp
   means no 0*inf path, so erf(+inf)=1, erf(-inf)=-1 (the correct limits), not NaN.

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO
   -fno-builtin (see branchless/log.c for the inliner-compatibility reason). */
extern double expm1(double);

/* exp(y) via the accurate expm1 leaf (L2-closure). exp(y) = 2^n*(expm1(r)+1),
   n = round(y/ln2), r in [-ln2/2, ln2/2]; the 2^n scale is split so a large
   negative y underflows to 0 instead of producing a bogus exponent field. */
static double bexp(double y) {
    const double ln2_hi = 6.93147180369123816490e-01;
    const double ln2_lo = 1.90821492927058770002e-10;
    const double invln2 = 1.44269504088896338700e+00;
    double kn   = y * invln2;
    double bias = (kn < 0.0) ? -0.5 : 0.5;              /* branchless round bias */
    int    n    = (int)(kn + bias);
    double dn   = (double)n;
    double r    = (y - dn * ln2_hi) - dn * ln2_lo;      /* reduced arg, near 0   */
    double er   = expm1(r) + 1.0;                        /* = exp(r), no cancel   */
    int nh = n >> 1, nl = n - nh;                        /* split exponent        */
    long long bh = (long long)(nh + 1023) << 52;
    long long bl = (long long)(nl + 1023) << 52;
    double sh, sl;
    __builtin_memcpy(&sh, &bh, 8);                       /* 2^nh (bitcast i64->f64) */
    __builtin_memcpy(&sl, &bl, 8);                       /* 2^nl                    */
    return er * sh * sl;                                 /* 2^n = 2^nh * 2^nl       */
}

double erf(double x) {
    /* openlibm s_erf.c minimax coefficients (double-precision, proven <1 ulp). */
    const double erx = 8.45062911510467529297e-01;
    const double pp0 = 1.28379167095512558561e-01, pp1 = -3.25042107247001499370e-01;
    const double pp2 = -2.84817495755985104766e-02, pp3 = -5.77027029648944159157e-03,
                 pp4 = -2.37630166566501626084e-05;
    const double qq1 = 3.97917223959155352819e-01, qq2 = 6.50222499887672944485e-02,
                 qq3 = 5.08130628187576562776e-03, qq4 = 1.32494738004321644526e-04,
                 qq5 = -3.96022827877536812320e-06;
    const double pa0 = -2.36211856075265944077e-03, pa1 = 4.14856118683748331666e-01,
                 pa2 = -3.72207876035701323847e-01, pa3 = 3.18346619901161753674e-01,
                 pa4 = -1.10894694282396677476e-01, pa5 = 3.54783043256182359371e-02,
                 pa6 = -2.16637559486879084300e-03;
    const double qa1 = 1.06420880400844228286e-01, qa2 = 5.40397917702171048937e-01,
                 qa3 = 7.18286544141962662868e-02, qa4 = 1.26171219808761642112e-01,
                 qa5 = 1.36370839120290507362e-02, qa6 = 1.19844998467991074170e-02;
    const double ra0 = -9.86494403484714822705e-03, ra1 = -6.93858572707181764372e-01,
                 ra2 = -1.05586262253232909814e+01, ra3 = -6.23753324503260060396e+01,
                 ra4 = -1.62396669462573470355e+02, ra5 = -1.84605092906711035994e+02,
                 ra6 = -8.12874355063065934246e+01, ra7 = -9.81432934416914548592e+00;
    const double sa1 = 1.96512716674392571292e+01, sa2 = 1.37657754143519042600e+02,
                 sa3 = 4.34565877475229228821e+02, sa4 = 6.45387271733267880336e+02,
                 sa5 = 4.29008140027567833386e+02, sa6 = 1.08635005541779435134e+02,
                 sa7 = 6.57024977031928170135e+00, sa8 = -6.04244152148580987438e-02;
    const double rb0 = -9.86494292470009928597e-03, rb1 = -7.99283237680523006574e-01,
                 rb2 = -1.77579549177547519889e+01, rb3 = -1.60636384855821916062e+02,
                 rb4 = -6.37566443368389627722e+02, rb5 = -1.02509513161107724954e+03,
                 rb6 = -4.83519191608651397019e+02;
    const double sb1 = 3.03380607434824582924e+01, sb2 = 3.25792512996573918826e+02,
                 sb3 = 1.53672958608443695994e+03, sb4 = 3.19985821950859553908e+03,
                 sb5 = 2.55305040643316442583e+03, sb6 = 4.74528541206955367215e+02,
                 sb7 = -2.24409524465858183362e+01;

    double t = __builtin_fabs(x);

    /* R1: erf = t + t*(P/Q), z = t^2 — clamp t so P/Q stays finite everywhere. */
    double t1 = __builtin_fmin(t, 0.84375);
    double z  = t1 * t1;
    double P  = pp0 + z * (pp1 + z * (pp2 + z * (pp3 + z * pp4)));
    double Q  = 1.0 + z * (qq1 + z * (qq2 + z * (qq3 + z * (qq4 + z * qq5))));
    double erf1 = t1 + t1 * (P / Q);

    /* R2: erf = erx + P1/Q1, s = t-1 — clamp t to [0.84375,1.25] so Q1 != 0. */
    double t2 = __builtin_fmax(__builtin_fmin(t, 1.25), 0.84375);
    double s  = t2 - 1.0;
    double P1 = pa0 + s * (pa1 + s * (pa2 + s * (pa3 + s * (pa4 + s * (pa5 + s * pa6)))));
    double Q1 = 1.0 + s * (qa1 + s * (qa2 + s * (qa3 + s * (qa4 + s * (qa5 + s * qa6)))));
    double erf2 = erx + P1 / Q1;

    /* R3+: erf = 1 - erfc(t) via the exp asymptotic — clamp te to [1.25,30]
       (30 > erf's ~6 saturation, keeps z^2 finite so erf=+-1 for all large x). */
    double te = __builtin_fmin(__builtin_fmax(t, 1.25), 30.0);
    double w  = 1.0 / (te * te);
    double Ra = ra0 + w * (ra1 + w * (ra2 + w * (ra3 + w * (ra4 + w * (ra5 + w * (ra6 + w * ra7))))));
    double Sa = 1.0 + w * (sa1 + w * (sa2 + w * (sa3 + w * (sa4 + w * (sa5 + w * (sa6 + w * (sa7 + w * sa8)))))));
    double Rb = rb0 + w * (rb1 + w * (rb2 + w * (rb3 + w * (rb4 + w * (rb5 + w * rb6)))));
    double Sb = 1.0 + w * (sb1 + w * (sb2 + w * (sb3 + w * (sb4 + w * (sb5 + w * (sb6 + w * sb7))))));
    double ua = (te < 2.857142857142857) ? 1.0 : 0.0;   /* 1/0.35 boundary weight */
    double R  = ua * Ra + (1.0 - ua) * Rb;
    double S  = ua * Sa + (1.0 - ua) * Sb;
    /* z = te with the low 32 mantissa bits cleared: z^2 is EXACT (<=42 bits), so
       exp(-z^2-0.5625) loses no precision to the squaring; the residual
       (z-te)(z+te) = z^2-te^2 rides the second exp (openlibm's Note1 split). */
    double zc;
    long long zi;
    __builtin_memcpy(&zi, &te, 8);
    zi &= 0xFFFFFFFF00000000LL;
    __builtin_memcpy(&zc, &zi, 8);
    double Eexp = bexp(-zc * zc - 0.5625) * bexp((zc - te) * (zc + te) + R / S) / te;
    double erf3 = 1.0 - Eexp;

    /* regime weights (constant-operand selects; exactly one is 1). */
    double w1 = (t < 0.84375) ? 1.0 : 0.0;
    double wB = (t < 1.25) ? 1.0 : 0.0;
    double w2 = wB - w1;                                 /* [0.84375, 1.25)      */
    double w3 = 1.0 - wB;                                /* [1.25, inf)          */
    double mag = w1 * erf1 + w2 * erf2 + w3 * erf3;      /* = erf(|x|), exact     */
    return __builtin_copysign(mag, x);                   /* keep-set leaf; odd fn */
}
