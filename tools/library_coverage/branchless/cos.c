/* branchless/cos.c — bd 3c6m.25 (libm L1): the AUTHORED branchless cos body the
   census injects for `cos` (Rule 18 source injection; owner body-source decision
   2026-07-10 = hand-author per fn, the slice_branchless_exp model). This file
   SHADOWS openlibm's branchy k_cos/e_cos in the census symbol index.

   *** WHY openlibm's cos DECLINES (the L5-shadow blocker). *** identical to sin —
   openlibm's Payne–Hanek range reduction stores the split product into the
   multi-word scratch `double tx[3]` and reads it back (e_rem_pio2.c:174 —
   `tainted value stored to memory`, the L5-shadow lever, the Phase-7.5 QRAM/Shadow
   surface). This body replaces it with a REGISTER-ONLY, BRANCHLESS Cody–Waite
   reduction; see branchless/sin.c for the full derivation. cos and sin share the
   SAME reduction and the SAME k_sin/k_cos kernels — they differ only in the
   quadrant offset.

   *** cos = sin(x + π/2). *** Adding π/2 leaves the reduced argument y unchanged
   (fn increases by exactly 1, y = (x+π/2) − (fn+1)·π/2 = x − fn·π/2) and shifts
   the quadrant by +1. So cos is authored as the branchless/sin.c quadrant/sign
   code applied to (fn+1):  qf = (fn+1) mod 4 selects  q'=0:+cos(y)  q'=1:−sin(y)
   q'=2:−cos(y)  q'=3:+sin(y)  via the same useS=(par<0.5)?1:0 kernel pick and
   sgn=(half<0.5)?1:−1 sign — every comparison a `<` against a CONSTANT, so clang
   -O1 keeps them speculatable `select`s (never branches; the equality form
   par==half WOULD branch-ify — see branchless/sin.c). Both kernels are computed
   unconditionally and blended by the UNCONDITIONAL weighted expression
   sgn·(useS·S + (1−useS)·C) — the atan.c/erf.c const-select-weight pattern, the
   kjd1 fp-DATA select accept shape (a libm body mints no Rz/Ry).

   *** FINITE OVER THE WHOLE DOMAIN. *** yc = fmax(-π/4, fmin(y, π/4)) with the
   NaN-suppressing hardware keep-set fmin/fmax — a NEAR-no-op on the faithful range
   (it fires only at the rare odd·π/4 rint-boundary input, where the double-rounded
   2/π lands the reduced arg a rounding-ulp past ±π/4, a ~1e-12 effect within the
   accuracy sanity margin) and a finite bound beyond it, so cos returns a finite
   value in [-1,1] for EVERY double including ±∞/NaN. No in-domain NaN/Inf; the
   branchless range-reduction limit surfaces only as reduced ACCURACY for
   |x| ≳ 1.65e6.

   The e2e golden twin is tests/e2e/slice_branchless_cos.c (same body, inlined at
   the slice level as `bcos`) — keep the two textually in sync.

   Accuracy (honest, one line; runtime is trace-only so ulp is a SANITY check, not
   a gate): matches host libm cos to ≈1 ulp for |x| ≲ 1.65e6 (exact at 1e6 in the
   spot-check), sub-ulp absolute (~1e-26) at the zeros; beyond that range finite
   but unspecified (the Payne–Hanek path this body omits). */
double cos(double x) {
    const double invpio2 = 6.36619772367581382433e-01; /* 2/π                     */
    const double pio2_1   = 1.57079632673412561417e+00; /* π/2, first 33 bits      */
    const double pio2_1t  = 6.07710050650619224932e-11; /* π/2 − pio2_1            */
    const double PIO4     = 0.78539816339744830962;     /* π/4 clamp guard         */
    const double S1 = -1.66666666666666324348e-01, S2 =  8.33333333332248946124e-03,
                 S3 = -1.98412698298579493134e-04, S4 =  2.75573137070700676789e-06,
                 S5 = -2.50507602534068634195e-08, S6 =  1.58969099521155010221e-10;
    const double C1 =  4.16666666666666019037e-02, C2 = -1.38888888888741095749e-03,
                 C3 =  2.48015872894767294178e-05, C4 = -2.75573143513906633035e-07,
                 C5 =  2.08757232129817482790e-09, C6 = -1.13596475577881948265e-11;

    double fn = __builtin_rint(x * invpio2);            /* keep-set leaf           */
    double y  = (x - fn * pio2_1) - fn * pio2_1t;       /* 2-term Cody–Waite       */
    double yc = __builtin_fmax(-PIO4, __builtin_fmin(y, PIO4)); /* finite guard    */

    double z = yc * yc, w = z * z;
    double rs = S2 + z * (S3 + z * S4) + z * w * (S5 + z * S6);
    double v  = z * yc;
    double S  = yc + v * (S1 + z * rs);                 /* sin(yc)                 */
    double rc = z * (C1 + z * (C2 + z * C3)) + w * w * (C4 + z * (C5 + z * C6));
    double hz = 0.5 * z, wc = 1.0 - hz;
    double C  = wc + (((1.0 - wc) - hz) + z * rc);       /* cos(yc)                 */

    /* cos = sin(x+π/2): sin-weight code on the +1-shifted quadrant. All-`<`-const
       selects (never the branch-ifying equality form).                           */
    double fq   = fn + 1.0;
    double qf   = fq - 4.0 * __builtin_floor(fq * 0.25);
    double half = __builtin_floor(qf * 0.5);
    double par  = qf - 2.0 * half;
    double useS = (par  < 0.5) ? 1.0 : 0.0;             /* even shifted quad → sin */
    double sgn  = (half < 0.5) ? 1.0 : -1.0;
    double mag  = useS * S + (1.0 - useS) * C;
    return sgn * mag;
}
