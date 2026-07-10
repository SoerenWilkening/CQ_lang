/* branchless/atan2.c — bd 3c6m.22 (libm L2-closure): the AUTHORED branchless
   atan2 body the census injects for `atan2` (Rule 18 source injection; owner
   body-source decision 2026-07-10 = hand-author per fn, the slice_branchless_exp
   model). This file SHADOWS openlibm's branchy e_atan2.c in the census index.

   openlibm's atan2 is a ladder of sign/zero/inf special cases (the L2/L6 blocker
   at e_atan2.c) around a single atan(|y/x|) call. This branchless body computes the
   principal atan(y/x) once and adds the quadrant offset as a CONSTANT-operand
   select on the signs of x and y:

       atan2(y,x) = atan(y/x) + ( x<0 ? (y<0 ? -pi : +pi) : 0 )

   *** WHY CONSTANT-OPERAND SELECTS. *** The quadrant offset arms are the literals
   {-pi, +pi, 0} — a select whose arms are constants stays a `select`, whereas a
   select with an expensive/speculatable arm gets SimplifyCFG-branch-ified at -O1
   into tainted control flow (the atan N/D lesson, see branchless/atan.c). The one
   unconditional division y/x feeds atan (resolved by the census closure-link to
   the authored branchless/atan.c, indexed first, and inlined — the L2-closure
   spine, mirrors tanh->expm1). atan itself contributes the kjd1 fp-DATA selects;
   there are NO branches.

   The census/e2e probe fixes x = 0.5 (a positive CONSTANT), so the whole quadrant
   select const-folds to 0 and the body reduces to atan(y/0.5) = atan(2y) — the
   x>0 half-plane. The general quadrant logic is present in the body and validated
   natively (host long-double atan2l over all four quadrants, worst ~1.35 true-ulp);
   only the x>0 path is exercised by the trace, exactly as the probe's constant x
   dictates.

   The e2e golden twin is tests/e2e/slice_branchless_atan2.c (same body, with atan
   inlined as the static `batan` helper) — keep the two textually in sync.

   Domain: finite x != 0 (the x>0 half is contractual via the probe; x<0 quadrants
   host-verified). The x = 0 axis is UNSPECIFIED — y/x = +-inf and branchless atan
   returns NaN there (0*inf in its big-segment N), not the mathematical +-pi/2 (the
   extended-real special cases this body omits). Signed-zero of a -0.0 y on the x<0
   axis is likewise UNSPECIFIED (y<0 is false for -0.0, so it takes +pi not -pi).
   Worst <=1.35 true-ulp (observed interior ~1.18) vs host long-double atan2l across the finite quadrants
   (metric: |g-ref|/ulp(ref); the branchless atan leaf dominates — a host-atan
   sweep understates this).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
extern double atan(double);

double atan2(double y, double x) {
    const double PI = 3.14159265358979311600;            /* nearest double to pi   */
    double off = (x < 0.0) ? (y < 0.0 ? -PI : PI) : 0.0; /* constant-operand select */
    return atan(y / x) + off;                            /* one division -> atan    */
}
