/* branchless/cosh.c — bd 3c6m.26 (libm L2-closure): the AUTHORED branchless cosh
   body the census injects for `cosh` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model). This
   file SHADOWS openlibm's branchy e_cosh.c in the census index.

   openlibm's cosh branches on |x| into several ranges (|x|<0.5ln2 / <22 /
   <ln(DBL_MAX) / larger — the L2/L6 blocker at e_cosh.c:68) to avoid the large-|x|
   overflow of e^x while keeping cosh accurate near 1. This branchless body keeps
   openlibm's OWN expm1 kernel and makes it valid for ALL |x| with the single
   overflow-safe identity (e = e^|x| = expm1(|x|) + 1):

       cosh(x) = 0.5 * ( e + 1/e ),   even fn (work on |x|)

   which is (e^|x| + e^-|x|)/2 exactly. cosh is even, so fabs makes the argument to
   expm1 non-negative (a raw negative-x expm1 -> -1 would send 1/e -> +inf). ZERO
   selects (beyond expm1's own inherited round-bias select), zero control flow:

     * OVERFLOW: 1/e is bounded by 1, so e + 1/e ~ e for large e (no new overflow)
       and 0.5*e = e^|x|/2 = cosh — valid right up to expm1's domain edge
       ln(DBL_MAX). openlibm's near-0 form 1 + t^2/(2w) would form t^2 and overflow.
     * NEAR 0: the |x| terms of e = 1+|x|+... and 1/e = 1-|x|+... cancel EXACTLY
       (that is cosh's even symmetry), leaving 2 + |x|^2 -> the correct cosh ~ 1 +
       |x|^2/2; the surviving |x|^2 is far above ulp(2), so no catastrophic loss.
       (For |x| < 1.5e-8 the |x|^2/2 term is below ulp(1) and cosh rounds to 1.0,
       exactly as host libm does.)

   It CALLS `expm1` — resolved by the census closure-link to the authored
   branchless/expm1.c (indexed first) and inlined (the L2-closure spine, identical
   to how tanh calls expm1). fabs is the hardware keep-set leaf. NO tables, NO
   control flow.

   The e2e golden twin is tests/e2e/slice_branchless_cosh.c (same body, with expm1
   inlined as the static `bexpm1` helper) — keep the three textually in sync
   (bexpm1 == branchless/expm1.c).

   Domain: finite x with |x| <= ln(DBL_MAX) ~ 709.78 (expm1's valid range; cosh
   itself overflows to +inf near |x| > 710.48 anyway). Beyond that, and inf/NaN, are
   UNSPECIFIED — the branchy special cases this body omits. cosh(+-0) = 1. Verified
   NaN-free on [-40,40] and the large band [690, 709.7] (expm1's half-scale fix
   keeps the n=1024 band clean), worst <=1.7 true-ulp (observed ~1.59) vs host long-double coshl
   (~0.70 ulp in the large band), correct even symmetry (metric: |g-ref|/ulp(ref);
   the branchless expm1 leaf, ~2 ulp, dominates — a host-expm1 sweep understates
   this).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
extern double expm1(double);

double cosh(double x) {
    double e = expm1(__builtin_fabs(x)) + 1.0;           /* e^|x| (even fn)       */
    return 0.5 * (e + 1.0/e);                            /* = cosh(x), no OVF     */
}
