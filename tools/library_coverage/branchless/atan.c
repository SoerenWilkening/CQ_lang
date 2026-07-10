/* branchless/atan.c — bd 3c6m.21 (libm L1): the AUTHORED branchless atan body
   the census injects for `atan` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model).
   This file SHADOWS openlibm's branchy s_atan.c in the census symbol index.

   openlibm's atan selects one of five |x| segments with a table of atan(k/8)
   breakpoints (s_atan.c's nested `if (ix < …)` ladder — the L6-nested-ctrl
   blocker at s_atan.c:81). This branchless body uses Cephes's THREE-segment
   argument reduction (a strictly tighter, fully-branchless scheme) rendered as
   pure fp SELECTS + ONE unconditional division:

       |x| > tan(3π/8)      : reduce to -1/|x|,      base angle π/2
       0.66 < |x| ≤ tan(3π/8): reduce to (|x|-1)/(|x|+1), base angle π/4
       |x| ≤ 0.66           : reduce to |x|,          base angle 0

   then Cephes's degree-4/5 rational R(z) (z = xr²) on the reduced range, and
   atan(|x|) = xr + xr·z·R(z) + base. The sign rides a final copysign (atan is
   odd) — the hardware keep-set leaf, exactly like cbrt's fabs.

   *** WHY THE REDUCTION IS A SINGLE DIVISION, NOT A PER-ARM ONE. *** The naive
   `(|x|>T3P8) ? -1/|x| : …` puts a division on ONE select arm; clang -O1's
   SimplifyCFG then BRANCH-ifies the select to skip the (speculatable-but-costly)
   fdiv on the other path — reintroducing exactly the tainted control flow this
   body exists to avoid ("condition data use … under quantum control"). Instead
   the reduced arg is xr = N/D with ONE unconditional division, where N and D are
   built from CONSTANT-operand selects (0/±1); a constant-valued select is cheap,
   so clang keeps it a `select` (never a branch). The angle offset is likewise a
   constant-operand select. All 5 surviving selects are the kjd1 fp-DATA select
   accept shape (fcmp condition, no Rz/Ry lineage — a libm body mints no
   rotations); the rational core is straight-line fmuladd + fdiv.

   The e2e golden twin is tests/e2e/slice_branchless_atan.c (same body, inlined
   at the slice level) — keep the two textually in sync.

   Accuracy: ≤1.15 ulp vs host libm over a 40M-point sweep on [-30,30] plus dense
   scans across BOTH reduction breakpoints (0.66, 2.4142 — the two adjacent
   segments agree there, no discontinuity spike) and the |x|→∞ tail. ±0 is exact
   (copysign preserves the signed zero). ±∞ / NaN are UNSPECIFIED, the convention
   for a branchless injected body — concretely atan(±∞) returns NaN here (in the
   big segment N = a·|x| + b evaluates 0·∞ = NaN), not the mathematical ±π/2; the
   special-case branches openlibm needs for the extended reals are deliberately
   omitted. Only the FINITE domain is contractual, and it is NaN-free through
   DBL_MAX (0·|x| = 0 exactly for every finite |x|).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c` with NO
   -fno-builtin — a "no-builtins" definition attribute would make the probe
   caller's no-builtin-atan set a non-superset and the O2 inliner then refuses
   to inline the body (TLI areInlineCompatible, InlineCallerSupersetNoBuiltin;
   see branchless/log.c). */
double atan(double x) {
    const double T3P8 = 2.41421356237309504880;         /* tan(3π/8)             */
    const double PIO2 = 1.57079632679489661923;
    const double PIO4 = 0.78539816339744830962;
    /* Cephes atan P (degree-4) / Q (monic degree-5) rational coefficients.      */
    const double P0 = -8.750608600031904122785e-1;
    const double P1 = -1.615753718733365076637e1;
    const double P2 = -7.500855792314704667340e1;
    const double P3 = -1.228866684490136173410e2;
    const double P4 = -6.485021904942025371773e1;
    const double Q0 =  2.485846490142306297962e1;
    const double Q1 =  1.650270098316988542046e2;
    const double Q2 =  4.328810604912902668951e2;
    const double Q3 =  4.853903996359136964868e2;
    const double Q4 =  1.945506571482613964425e2;

    double ax = __builtin_fabs(x);                       /* keep-set leaf         */
    int big = ax > T3P8;
    int mid = ax > 0.66;                                 /* big implies mid       */

    /* reduced arg xr = N/D: ONE unconditional division, constant-operand selects
       (N,D never both-zero; D ∈ {1, |x|+1≥1, |x|>T3P8} so never 0).            */
    double a = big ? 0.0 : 1.0;
    double b = mid ? -1.0 : 0.0;
    double c = mid ? 1.0 : 0.0;
    double d = big ? 0.0 : 1.0;
    double N = a * ax + b;
    double D = c * ax + d;
    double xr = N / D;

    /* base angle. Cephes's per-segment MOREBITS (~6e-17) low-order correction is
       OMITTED: it is meaningful only added to the SMALL reduced result, not to the
       double-rounded base angle (PIO2 + MB == PIO2 as a double — a no-op). A
       single-double branchless body accepts that ~0.28-ulp deficit; still ≤1.15 ulp. */
    double y = big ? PIO2 : (mid ? PIO4 : 0.0);

    double z = xr * xr;
    double pnum = (((P0 * z + P1) * z + P2) * z + P3) * z + P4;   /* polevl(z,P,4) */
    double pden = ((((z + Q0) * z + Q1) * z + Q2) * z + Q3) * z + Q4; /* p1evl(z,Q,5) */
    double r = z * pnum / pden;
    double res = xr * r + xr + y;
    return __builtin_copysign(res, x);                   /* keep-set leaf; odd fn */
}
