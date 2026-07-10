/* branchless/erfc.c — bd 3c6m.28 (libm L2-closure): the AUTHORED branchless erfc
   body the census injects for `erfc` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model). This
   file SHADOWS openlibm's branchy s_erf.c (erfc) in the census symbol index.

   Structure identical to branchless/erf.c (read its header for the const-select
   0/1 weight + unconditional weighted-sum dispatch, the clamped-finite regime
   evaluation, and the exp-via-expm1 L2-closure spine). erfc differs from erf ONLY
   in the near-0 reconstruction and the sign fold, both to keep erfc — which does
   NOT saturate the way erf does — cancellation-free:

     R1  t < 0.84375   erfc = 1 - (t + t*y)          if t < 0.25   (openlibm)
                            = 0.5 - ((t-0.5) + t*y)   if t >= 0.25   (avoids the
                       1-x cancellation for x in [0.25,0.84]), y = P(z)/Q(z).
     R2  0.84375<=t<1.25  erfc = (1-erx) - P1/Q1      (NOT 1-(erx+P1/Q1): the
                       constant (1-erx)=0.155 keeps the subtraction well-scaled).
     R3+ t >= 1.25        erfc = exp(-z^2-0.5625)*exp((z-t)(z+t)+R/S)/t   DIRECTLY
                       (the tail value itself — erf's 1-erfc would cancel it away).

   These give erfc(|x|) = E >= 0; the even/reflection fold for x<0 is
   erfc(x) = x<0 ? 2-E : E, expressed as the const-select weight `sgn` so the tail
   E is never routed through a cancelling 1-copysign(1-E) (which would lose E for
   large positive x). It CALLS `expm1` (resolved by the census closure-link to the
   authored branchless/expm1.c and inlined; the L2-closure spine, mirroring
   sinh/cosh->expm1). fabs/fmin/fmax are the hardware keep-set leaves. NO tables,
   NO control flow.

   The e2e golden twin is tests/e2e/slice_branchless_erfc.c (same body, with expm1
   inlined as the static `bexpm1` helper) — keep the three textually in sync
   (bexpm1 == branchless/expm1.c; bexp/erfc identical).

   Domain: finite x. erfc(x>0) underflows to 0 by x~27.23 (below DBL_MIN); erfc(0)=1,
   erfc(-x)=2-erfc(x). Accuracy vs a 50-digit mpmath reference composing the
   BRANCHLESS expm1 leaf (metric |g-ref|/ulp(ref); host erfcl is itself ~7 ulp off
   in the R4 asymptotic and OVERSTATES the error — mpmath is the honest reference):
   <=2 ulp over the bulk of the domain, rising to a WORST of ~4.0 ulp in the R2/R3
   breakpoint band, where a CLUSTER of hard-to-round points lands up to 4 doubles
   (~4.0 fractional ulp; observed peak 3.99 at x=1.3371898113192247, dps=400) from
   correctly-rounded. That worst is INHERENT, not a leaf artifact: openlibm's R3
   exp-asymptotic formula is itself ~3 ulp in double there even with a
   perfectly-rounded exp (the log-then-exp of the R/S rational amplifies rounding),
   and the branchless expm1 leaf composition adds the last ~1 ulp. It is the corpus
   worst by a hair (acosh ~3.97 ulp). METHODOLOGY NOTE (Rule 10): the >3-ulp band is INVISIBLE to
   random/uniform sampling (which peaks at ~2.75) AND is UNDERSTATED by any single
   named double (adjacent 4-double-off points range 3.7-4.0 fractional ulp) — the
   ceiling is only pinned by dense ulp-scale CONTIGUOUS-double grids spanning the
   whole breakpoint band. te is clamped to [1.25,30]
   so the tail underflows cleanly (erfc=0 for x in [~27.23,DBL_MAX], correct)
   instead of overflowing z^2. +-0 -> 1. inf/NaN are UNSPECIFIED (the branchy
   special cases this body omits); because te is clamped there is no 0*inf path, so
   erfc(+inf)=0, erfc(-inf)=2 here (the correct limits) rather than NaN.

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO
   -fno-builtin (see branchless/log.c for the inliner-compatibility reason). */
extern double expm1(double);

/* exp(y) via the accurate expm1 leaf (L2-closure). See branchless/erf.c. */
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

double erfc(double x) {
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

    /* R1 shared kernel y = P(z)/Q(z), z = t^2 (clamped finite). */
    double t1 = __builtin_fmin(t, 0.84375);
    double z  = t1 * t1;
    double P  = pp0 + z * (pp1 + z * (pp2 + z * (pp3 + z * pp4)));
    double Q  = 1.0 + z * (qq1 + z * (qq2 + z * (qq3 + z * (qq4 + z * qq5))));
    double y  = P / Q;
    /* openlibm's cancellation-free R1 sub-forms (weight at 0.25). */
    double r1a = 1.0 - (t1 + t1 * y);                    /* t < 0.25             */
    double r1b = 0.5 - ((t1 - 0.5) + t1 * y);            /* 0.25 <= t < 0.84375  */
    double wq  = (t < 0.25) ? 1.0 : 0.0;
    double erfc1 = wq * r1a + (1.0 - wq) * r1b;

    /* R2: erfc = (1-erx) - P1/Q1 directly (clamp t to [0.84375,1.25], Q1 != 0). */
    double t2 = __builtin_fmax(__builtin_fmin(t, 1.25), 0.84375);
    double s  = t2 - 1.0;
    double P1 = pa0 + s * (pa1 + s * (pa2 + s * (pa3 + s * (pa4 + s * (pa5 + s * pa6)))));
    double Q1 = 1.0 + s * (qa1 + s * (qa2 + s * (qa3 + s * (qa4 + s * (qa5 + s * qa6)))));
    double erfc2 = (1.0 - erx) - P1 / Q1;

    /* R3+: erfc = exp(-z^2-0.5625)*exp((z-t)(z+t)+R/S)/t DIRECTLY (te clamped). */
    double te = __builtin_fmin(__builtin_fmax(t, 1.25), 30.0);
    double w  = 1.0 / (te * te);
    double Ra = ra0 + w * (ra1 + w * (ra2 + w * (ra3 + w * (ra4 + w * (ra5 + w * (ra6 + w * ra7))))));
    double Sa = 1.0 + w * (sa1 + w * (sa2 + w * (sa3 + w * (sa4 + w * (sa5 + w * (sa6 + w * (sa7 + w * sa8)))))));
    double Rb = rb0 + w * (rb1 + w * (rb2 + w * (rb3 + w * (rb4 + w * (rb5 + w * rb6)))));
    double Sb = 1.0 + w * (sb1 + w * (sb2 + w * (sb3 + w * (sb4 + w * (sb5 + w * (sb6 + w * sb7))))));
    double ua = (te < 2.857142857142857) ? 1.0 : 0.0;
    double R  = ua * Ra + (1.0 - ua) * Rb;
    double S  = ua * Sa + (1.0 - ua) * Sb;
    double zc;
    long long zi;
    __builtin_memcpy(&zi, &te, 8);
    zi &= 0xFFFFFFFF00000000LL;
    __builtin_memcpy(&zc, &zi, 8);
    double Eexp = bexp(-zc * zc - 0.5625) * bexp((zc - te) * (zc + te) + R / S) / te;

    /* regime weights (constant-operand selects; exactly one is 1). */
    double w1 = (t < 0.84375) ? 1.0 : 0.0;
    double wB = (t < 1.25) ? 1.0 : 0.0;
    double w2 = wB - w1;
    double w3 = 1.0 - wB;
    double E  = w1 * erfc1 + w2 * erfc2 + w3 * Eexp;     /* = erfc(|x|), exact    */

    /* reflection fold erfc(x) = x<0 ? 2-E : E (const-select weight; no 1-E form
       so the tail E survives for large positive x). */
    double sgn = (x < 0.0) ? 1.0 : 0.0;
    return (1.0 - sgn) * E + sgn * (2.0 - E);
}
