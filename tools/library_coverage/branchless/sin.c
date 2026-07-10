/* branchless/sin.c — bd 3c6m.44 (libm L1): the AUTHORED branchless sin body the
   census injects for `sin` (Rule 18 source injection; owner body-source decision
   2026-07-10 = hand-author per fn, the slice_branchless_exp model). This file
   SHADOWS openlibm's branchy k_sin/e_sin in the census symbol index.

   *** WHY openlibm's sin DECLINES (the L5-shadow blocker). *** openlibm reduces an
   arbitrary x to [-π/4,π/4] with Payne–Hanek, which stores the split product into
   a multi-word scratch array `double tx[3]` and reads it back (e_rem_pio2.c:174 —
   `tainted value stored to memory`, the L5-shadow lever). A tainted store→load
   through that scratch is the Phase-7.5 QRAM/Shadow surface, not yet lowerable, so
   the stock body is declined. This body replaces Payne–Hanek with a fully
   REGISTER-ONLY, BRANCHLESS Cody–Waite reduction (no scratch array, no branches):

       fn = rint(x · 2/π)                 nearest quarter-turn count
       y  = (x − fn·pio2_1) − fn·pio2_1t  reduced arg in [-π/4,π/4] (2-term C-W)

   pio2_1 is π/2 truncated to 33 bits and pio2_1t its tail, so the two-term
   subtraction cancels ≈66 bits of π/2 — faithful for |x| ≲ 2^20·(π/2) ≈ 1.65e6
   (fdlibm's own "medium size" threshold). Then fdlibm's degree-6 k_sin / k_cos
   minimax kernels on the reduced arg, and the QUADRANT (fn mod 4) selects the
   answer:  q=0:+sin(y)  q=1:+cos(y)  q=2:-sin(y)  q=3:-cos(y).

   *** WHY THE QUADRANT IS FP CONST-SELECTS, NOT INTEGER + DATA-SELECT. *** The
   quadrant is derived ENTIRELY in fp — qf = fn − 4·floor(fn/4) ∈ {0,1,2,3},
   par = qf mod 2, half = floor(qf/2) — via the hardware keep-set `floor`, so
   there is no fptosi/int-mask. Both kernels S=k_sin(y), C=k_cos(y) are computed
   UNCONDITIONALLY (cheap polynomials) and blended by CONSTANT-operand fp selects:
   useS=(par<0.5)?1:0 picks the kernel, sgn=(half<0.5)?1:-1 the sign, and the
   answer is the UNCONDITIONAL weighted expression  sgn·(useS·S + (1−useS)·C).
   A constant-operand select on a `<` against a literal is speculatable, so clang
   -O1 keeps it a `select` (never a branch) — exactly the atan.c/erf.c pattern (a
   libm body mints no Rz/Ry, so the kjd1 fp-DATA select accept shape applies: fcmp
   condition, no rotation lineage). An EQUALITY-of-two-computed-values select
   (par==half) IS branch-ified by SimplifyCFG — so cos(x) is authored as this same
   sin-weight code applied to (fn+1) (cos = sin(x+π/2): identical reduced arg,
   quadrant shifted +1), keeping every comparison a `<` against a constant.

   *** FINITE OVER THE WHOLE DOMAIN. *** The reduced arg is clamped
   yc = fmax(-π/4, fmin(y, π/4)) with the hardware keep-set (NaN-suppressing)
   fmin/fmax. On the faithful range the clamp is a NEAR-no-op — it fires only at the
   rare input near an odd multiple of π/4, where the double-rounded 2/π lands the
   reduced arg a rounding-ulp OUTSIDE ±π/4 (a ~1e-12 effect, within the accuracy
   sanity margin below); beyond the faithful range (where two-term Cody–Waite loses
   accuracy and the raw y would overflow z=y² into the kernels) it bounds the
   argument so the body returns a FINITE value in [-1,1] for EVERY double —
   including ±∞/NaN (fmin/fmax return the non-NaN operand). No in-domain NaN/Inf
   anywhere; the branchless range-reduction limit surfaces only as reduced ACCURACY
   for |x| beyond ~1.65e6, never as a non-finite result. ±0 → +0 (there is no final
   copysign, so the sign of a zero result is not preserved — a signed-zero UNSPEC
   edge, harmless: +0.0 == -0.0; cf. atan2's signed-zero convention).

   The e2e golden twin is tests/e2e/slice_branchless_sin.c (same body, inlined at
   the slice level as `bsin`) — keep the two textually in sync.

   Accuracy (honest, one line; runtime is trace-only so ulp is a SANITY check, not
   a gate): matches host libm sin to ≈1 ulp for |x| ≲ 1.65e6 (exact at 1e6 in the
   spot-check), with sub-ulp absolute error (~1e-26) at the transcendental zeros;
   |x| beyond that range is finite but unspecified (the Payne–Hanek path this body
   deliberately omits). Compile like the rest of the corpus (see inject_census.py:
   blanket -fno-builtin; __builtin_* leaves are explicit and unaffected). */
double sin(double x) {
    const double invpio2 = 6.36619772367581382433e-01; /* 2/π                     */
    const double pio2_1   = 1.57079632673412561417e+00; /* π/2, first 33 bits      */
    const double pio2_1t  = 6.07710050650619224932e-11; /* π/2 − pio2_1            */
    const double PIO4     = 0.78539816339744830962;     /* π/4 clamp guard         */
    /* fdlibm k_sin degree-6 minimax (k_sin.c).                                    */
    const double S1 = -1.66666666666666324348e-01, S2 =  8.33333333332248946124e-03,
                 S3 = -1.98412698298579493134e-04, S4 =  2.75573137070700676789e-06,
                 S5 = -2.50507602534068634195e-08, S6 =  1.58969099521155010221e-10;
    /* fdlibm k_cos degree-6 minimax (k_cos.c).                                    */
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

    /* quadrant in fp (no fptosi): qf = fn mod 4 ∈ {0,1,2,3}, par = qf mod 2,
       half = floor(qf/2). Kernel + sign by constant-operand fp selects.          */
    double qf   = fn - 4.0 * __builtin_floor(fn * 0.25);
    double half = __builtin_floor(qf * 0.5);
    double par  = qf - 2.0 * half;
    double useS = (par  < 0.5) ? 1.0 : 0.0;             /* even quadrant → sin     */
    double sgn  = (half < 0.5) ? 1.0 : -1.0;            /* q≥2 → negate            */
    double mag  = useS * S + (1.0 - useS) * C;
    return sgn * mag;
}
