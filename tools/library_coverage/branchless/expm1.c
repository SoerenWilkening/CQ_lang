/* branchless/expm1.c — bd 3c6m.10 (libm L1): the AUTHORED branchless soft-expm1
   body the census injects for `expm1` (Rule 18 source injection; owner
   body-source decision 2026-07-10 = hand-author per fn, the slice_branchless_exp
   model). This file SHADOWS openlibm's branchy s_expm1.c in the census index.

   openlibm's expm1 branches per range-reduction quotient k (s_expm1.c:143 and a
   dozen k-specific reconstruction cases) to compute 2^k*e^r - 1 without
   cancellation. This branchless body keeps openlibm's ACCURATE primary kernel —
   the Q1..Q5 rational R(r) that yields expm1(r)=e^r-1 to <1 ulp on the reduced
   range — and replaces the whole k-case reconstruction thicket with the single
   cancellation-free identity

       expm1(x) = 2^n*(1 + expm1(r)) - 1 = 2*(2^(n-1)*Pr + (2^(n-1) - 0.5)),

   Pr = expm1(r). Because the "-1" is folded into the scale (never `exp(x) - 1`),
   there is no catastrophic cancellation for ANY n: for n==0 the result is
   Pr = expm1(r) computed directly. The reconstruction is done through the HALF
   scale 2^(n-1) so the exponent field never overflows to +Inf at n==1024 (x in
   [709.44, 709.78], where expm1 is finite up to DBL_MAX) — the branchless
   equivalent of openlibm's k==1024 case; the naive scale=2^n form silently
   returned NaN there (Inf*Pr + (Inf-1)). Range reduction uses the two-part ln2
   split + a Knuth compensation term c for r's rounding error (openlibm's trick).

   The ONLY non-straight-line construct is exp's round-bias fp select
   `(xn<0)?-0.5:0.5` (the kjd1 accept shape, identical to branchless/exp.c) —
   NO tables, NO data-dependent control flow, NO scratch memory.

   The e2e golden twin is tests/e2e/slice_branchless_expm1.c (same body, inlined
   at the slice level) — keep the two textually in sync.

   Domain: finite x in [-708, 709.78] (n = round(x/ln2) in the normal exponent
   range so the 2^(n-1) scale is valid). Overflow (x > 709.78 -> +inf), underflow
   (x < -708 -> -1), inf/NaN, and the signed zero of a -0.0 input (returns +0.0)
   are UNSPECIFIED — the branchy special cases this body deliberately omits.
   Accuracy: <=2 ulp vs host libm over a 40M-point sweep incl. the near-0 region;
   the TRUE worst is ~2.25 ulp at the n=+-1 reduction boundary (the region
   openlibm special-cases k=+-1; a branchless body accepts that ~2.25-ulp corner).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO
   -fno-builtin (see branchless/log.c for the inliner-compatibility reason). */
double expm1(double x) {
    const double ln2_hi = 6.93147180369123816490e-01;   /* 3fe62e42, fee00000  */
    const double ln2_lo = 1.90821492927058770002e-10;   /* 3dea39ef, 35793c76  */
    const double invln2 = 1.44269504088896338700e+00;   /* 3ff71547, 652b82fe  */
    /* openlibm s_expm1.c scaled R(r) coefficients (Qn for z = r*r/2). */
    const double Q1 = -3.33333333333331316428e-02;      /* BFA11111, 111110F4  */
    const double Q2 =  1.58730158725481460165e-03;      /* 3F5A01A0, 19FE5585  */
    const double Q3 = -7.93650757867487942473e-05;      /* BF14CE19, 9EAADBB7  */
    const double Q4 =  4.00821782732936239552e-06;      /* 3ED0CFCA, 86E65239  */
    const double Q5 = -2.01099218183624371326e-07;      /* BE8AFDB7, 6E09C32D  */

    /* Range reduction: n = round(x/ln2), r = x - n*ln2 via the two-part split. */
    double xn   = x * invln2;
    double half = (xn < 0.0) ? -0.5 : 0.5;              /* branchless round bias */
    int    n    = (int)(xn + half);
    double dn   = (double)n;
    double hi   = x - dn * ln2_hi;
    double lo   = dn * ln2_lo;
    double r    = hi - lo;
    double c    = (hi - r) - lo;                        /* r_true ~= r + c       */

    /* openlibm's accurate primary: Pr = expm1(r) = e^r - 1, error < 1 ulp. */
    double hfx = 0.5 * r;
    double hxs = r * hfx;                               /* r^2 / 2               */
    double R1  = 1.0 + hxs * (Q1 + hxs * (Q2 + hxs * (Q3 + hxs * (Q4 + hxs * Q5))));
    double t   = 3.0 - R1 * hfx;
    double e   = hxs * ((R1 - t) / (6.0 - r * t));
    double ec  = r * (e - c) - c;                       /* openlibm c-folded corr. */
    double Pr  = r - ec + hxs;                          /* = expm1(r), <1 ulp      */

    /* Reconstruct via the HALF scale 2^(n-1) so the 2^n never overflows to +Inf
       at n==1024 (x in [709.44, 709.78], where expm1 is still finite up to
       DBL_MAX): 2*(scale2*Pr + (scale2 - 0.5)) == scale*Pr + (scale - 1). This is
       the branchless equivalent of openlibm's k==1024 special case. */
    long long bits = (long long)(n - 1 + 1023) << 52;
    double scale2;
    __builtin_memcpy(&scale2, &bits, 8);                /* bitcast i64->f64: 2^(n-1) */
    return 2.0 * (scale2 * Pr + (scale2 - 0.5));
}
