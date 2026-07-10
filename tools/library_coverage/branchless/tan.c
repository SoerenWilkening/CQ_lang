/* branchless/tan.c — bd 3c6m.46 (libm L1): the AUTHORED branchless tan body the
   census injects for `tan` (Rule 18 source injection; owner body-source decision
   2026-07-10 = hand-author per fn, the slice_branchless_exp model). This file
   SHADOWS openlibm's branchy k_tan/e_tan in the census symbol index.

   *** WHY openlibm's tan DECLINES (the L5-shadow blocker). *** identical to sin/cos:
   openlibm reduces an arbitrary x to [-π/4,π/4] with Payne–Hanek, which stores the
   split product into a multi-word scratch array `double tx[3]` and reads it back
   (e_rem_pio2.c:174 — `tainted value stored to memory`, the Phase-7.5 QRAM/Shadow
   surface). This body REUSES the register-only, BRANCHLESS 2-term Cody–Waite
   reduction of branchless/sin.c (see there for the full derivation) and reconstructs
   tan from the SAME fdlibm k_sin/k_cos kernels as a RATIO — no k_tan table, no
   scratch memory, no branches.

   *** tan IS π-PERIODIC — ONLY THE PARITY OF fn MATTERS. *** With fn = rint(x·2/π)
   and reduced arg y = x − fn·π/2 ∈ [-π/4,π/4], x = y + fn·π/2 and (since tan has
   period π, not 2π) tan(x) depends ONLY on fn mod 2:
       fn even : tan(x) = tan(y)        =  sin(y)/cos(y)  =  S/C
       fn odd  : tan(x) = tan(y+π/2)    = -cot(y)         = -C/S
   No half/sign quadrant business (that is sin/cos's 4-way concern); tan needs one
   parity bit. The ratio is WELL-CONDITIONED on the reduced range — cos(y) ∈ [√2/2,1]
   is never near 0, so S/C is stable; C/S blows up only as y→0 in the ODD case, which
   is exactly x → an odd multiple of π/2, the genuine POLE of tan (→ ±∞, correct).

   *** WHY PARITY IS FP CONST-SELECT WEIGHTS, NOT INTEGER + DATA-SELECT. *** par is
   derived ENTIRELY in fp — par = fn − 2·floor(fn/2) ∈ {0,1} — via the hardware
   keep-set `floor` (no fptosi/int-mask). Both S=k_sin(y), C=k_cos(y) are computed
   UNCONDITIONALLY (needed by BOTH the even and odd forms — there is no expensive arm
   to sink onto a branch), and the two ratio operands are built by a CONSTANT-operand
   fp select feeding UNCONDITIONAL weighted sums with ONE division:
       useT = (par < 0.5) ? 1.0 : 0.0       even quadrant → tan = S/C
       num  = useT·S + (1−useT)·(−C)         S (even)  |  −C (odd)
       den  = useT·C + (1−useT)·  S          C (even)  |   S (odd)
       tan  = num / den                      ONE unconditional fdiv
   A constant-operand select on a `<` against a literal is speculatable, so clang -O1
   keeps it a `select` (never a branch) — exactly the sin.c/atan.c/erf.c pattern (a
   libm body mints no Rz/Ry, so the kjd1 fp-DATA select accept shape applies: fcmp
   condition, no rotation lineage). Because num/den are UNCONDITIONAL arithmetic over
   always-computed S,C and the fdiv is unconditional, clang cannot branch-ify a
   costly arm (the cos-equality trap of sin.c does not arise: the comparison is
   `<` against a CONSTANT, never equality-of-two-computed-values).

   *** FINITE OVER THE FINITE DOMAIN (except the true poles). *** The reduced arg is
   clamped yc = fmax(-π/4, fmin(y, π/4)) with the NaN-suppressing hardware keep-set
   fmin/fmax, so S and C are finite for EVERY double (±∞/NaN input → yc = ±π/4, a
   finite bound; huge |x| where raw z=y² would overflow → bounded). den = 0 occurs
   ONLY in the odd case at y = 0 exactly (x an odd multiple of π/2) — the genuine
   pole — where num = −cos(0) = −1 ≠ 0, so tan = −1/0 = ∓∞ (the correct pole limit),
   never 0/0 → so there is NO in-domain NaN. tan is unbounded (unlike sin/cos/erf),
   so ±∞ AT THE POLES is mathematically correct, not a defect. ±0 → +0 (no final
   copysign; a signed-zero UNSPEC edge, harmless: +0.0 == −0.0, cf. atan2).

   The e2e golden twin is tests/e2e/slice_branchless_tan.c (same body, inlined at the
   slice level as `btan`) — keep the two textually in sync.

   Accuracy (honest, one line; runtime is trace-only so ulp is a SANITY check, not a
   gate): matches host libm tan to ≈2 ulp for |x| ≲ 1.65e6 away from the poles (the
   ratio of two ≈1-ulp kernels), degrading near the poles where tan itself is
   ill-conditioned; |x| beyond that range is finite but unspecified (the Payne–Hanek
   path this body deliberately omits). Compile like the rest of the corpus (see
   inject_census.py: blanket -fno-builtin; __builtin_* leaves are explicit). */
double tan(double x) {
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

    /* parity in fp (no fptosi): par = fn mod 2 ∈ {0,1}. Ratio operands by a
       constant-operand fp select feeding UNCONDITIONAL weighted sums; ONE fdiv.    */
    double par  = fn - 2.0 * __builtin_floor(fn * 0.5);
    double useT = (par < 0.5) ? 1.0 : 0.0;              /* even quadrant → S/C     */
    double num  = useT * S + (1.0 - useT) * (-C);       /* S (even) | −C (odd)     */
    double den  = useT * C + (1.0 - useT) *   S;        /* C (even) |  S (odd)     */
    return num / den;
}
