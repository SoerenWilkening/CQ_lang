/* slice_branchless_erfc.c — bd 3c6m.28 / L2-closure: a source-injected
   transcendental (Rule 18), landed by the L1 branchless-authored body spine. A
   BRANCHLESS soft-erfc is authored inline, so clang -O1 inlines it to stock
   reversible OPCODES and the taint pass lowers those (no per-fn cq_template_erfc).

   Structure identical to slice_branchless_erf.c (const-select 0/1 weight +
   unconditional weighted-sum dispatch over openlibm's own minimax coefficients,
   exp-via-expm1 L2-closure spine). erfc differs only in the cancellation-free
   near-0 reconstruction and the reflection fold — it does NOT saturate the way
   erf does, so it must keep the tail value directly:

     R1  t<0.84375   erfc = 1-(t+t*y) [t<0.25] or 0.5-((t-0.5)+t*y) [else], y=P/Q
     R2  0.84375<=t<1.25   erfc = (1-erx) - P1/Q1   (NOT 1-(erx+P1/Q1))
     R3+ t>=1.25           erfc = exp(-z^2-0.5625)*exp((z-t)(z+t)+R/S)/t DIRECTLY.
   erfc(x) = x<0 ? 2-E : E via a const-select weight (never 1-copysign(1-E), which
   would cancel away the tail for large positive x).

   The corpus twin (tools/library_coverage/branchless/erfc.c) CALLS expm1
   (resolved by the census closure-link to branchless/expm1.c and inlined,
   mirroring sinh/cosh->expm1); here the branchless expm1 kernel is inlined as the
   static `bexpm1` helper. fabs/fmin/fmax are the hardware keep-set leaves.

   Domain: finite x; erfc(x>0) underflows to 0 by x~27.23. A faithful branchless
   erfc over openlibm's coefficients (spot-checked to a few ulp; trace-only runtime,
   so classical ulp is a sanity check, not a gate). +-0 -> 1. inf/NaN UNSPECIFIED
   (te-clamp gives the correct 0/2 limits, not NaN).

   The corpus twins are tools/library_coverage/branchless/{erfc,expm1}.c (same
   bodies) — keep the three textually in sync (bexpm1 == branchless/expm1.c;
   bexp/erfc == branchless/erfc.c). */

/* the branchless expm1 kernel, inlined (== tools/library_coverage/branchless/expm1.c) */
static double bexpm1(double x) {
    const double ln2_hi = 6.93147180369123816490e-01;
    const double ln2_lo = 1.90821492927058770002e-10;
    const double invln2 = 1.44269504088896338700e+00;
    const double Q1 = -3.33333333333331316428e-02;
    const double Q2 =  1.58730158725481460165e-03;
    const double Q3 = -7.93650757867487942473e-05;
    const double Q4 =  4.00821782732936239552e-06;
    const double Q5 = -2.01099218183624371326e-07;
    double xn   = x * invln2;
    double half = (xn < 0.0) ? -0.5 : 0.5;
    int    n    = (int)(xn + half);
    double dn   = (double)n;
    double hi   = x - dn * ln2_hi;
    double lo   = dn * ln2_lo;
    double r    = hi - lo;
    double c    = (hi - r) - lo;
    double hfx = 0.5 * r;
    double hxs = r * hfx;
    double R1  = 1.0 + hxs * (Q1 + hxs * (Q2 + hxs * (Q3 + hxs * (Q4 + hxs * Q5))));
    double t   = 3.0 - R1 * hfx;
    double e   = hxs * ((R1 - t) / (6.0 - r * t));
    double ec  = r * (e - c) - c;
    double Pr  = r - ec + hxs;
    long long bits = (long long)(n - 1 + 1023) << 52;
    double scale2;
    __builtin_memcpy(&scale2, &bits, 8);
    return 2.0 * (scale2 * Pr + (scale2 - 0.5));
}

/* exp(y) = 2^n*(expm1(r)+1) via the accurate expm1 leaf (== branchless/erfc.c bexp) */
static double bexp(double y) {
    const double ln2_hi = 6.93147180369123816490e-01;
    const double ln2_lo = 1.90821492927058770002e-10;
    const double invln2 = 1.44269504088896338700e+00;
    double kn   = y * invln2;
    double bias = (kn < 0.0) ? -0.5 : 0.5;
    int    n    = (int)(kn + bias);
    double dn   = (double)n;
    double r    = (y - dn * ln2_hi) - dn * ln2_lo;
    double er   = bexpm1(r) + 1.0;
    int nh = n >> 1, nl = n - nh;
    long long bh = (long long)(nh + 1023) << 52;
    long long bl = (long long)(nl + 1023) << 52;
    double sh, sl;
    __builtin_memcpy(&sh, &bh, 8);
    __builtin_memcpy(&sl, &bl, 8);
    return er * sh * sl;
}

static double berfc(double x) {
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
    double t1 = __builtin_fmin(t, 0.84375);
    double z  = t1 * t1;
    double P  = pp0 + z * (pp1 + z * (pp2 + z * (pp3 + z * pp4)));
    double Q  = 1.0 + z * (qq1 + z * (qq2 + z * (qq3 + z * (qq4 + z * qq5))));
    double y  = P / Q;
    double r1a = 1.0 - (t1 + t1 * y);
    double r1b = 0.5 - ((t1 - 0.5) + t1 * y);
    double wq  = (t < 0.25) ? 1.0 : 0.0;
    double erfc1 = wq * r1a + (1.0 - wq) * r1b;
    double t2 = __builtin_fmax(__builtin_fmin(t, 1.25), 0.84375);
    double s  = t2 - 1.0;
    double P1 = pa0 + s * (pa1 + s * (pa2 + s * (pa3 + s * (pa4 + s * (pa5 + s * pa6)))));
    double Q1 = 1.0 + s * (qa1 + s * (qa2 + s * (qa3 + s * (qa4 + s * (qa5 + s * qa6)))));
    double erfc2 = (1.0 - erx) - P1 / Q1;
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
    double w1 = (t < 0.84375) ? 1.0 : 0.0;
    double wB = (t < 1.25) ? 1.0 : 0.0;
    double w2 = wB - w1;
    double w3 = 1.0 - wB;
    double E  = w1 * erfc1 + w2 * erfc2 + w3 * Eexp;
    double sgn = (x < 0.0) ? 1.0 : 0.0;
    return (1.0 - sgn) * E + sgn * (2.0 - E);
}

double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(berfc(q));
}
int main(void) { (void) slice(); return 0; }
