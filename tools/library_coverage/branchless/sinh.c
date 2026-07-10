/* branchless/sinh.c — bd 3c6m.45 (libm L2-closure): the AUTHORED branchless sinh
   body the census injects for `sinh` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model). This
   file SHADOWS openlibm's branchy e_sinh.c in the census index.

   openlibm's sinh branches on |x| into four ranges (|x|<1 / 1<=|x|<22 / 22<=|x|<
   ln(DBL_MAX) / larger — the L2/L6 blocker at e_sinh.c:67) to avoid BOTH the near-0
   cancellation of (e^x - e^-x) AND the large-|x| overflow of e^x. This branchless
   body keeps openlibm's OWN expm1 kernel and makes it valid for ALL |x| with the
   single overflow-safe identity (h = 0.5, t = expm1(|x|)):

       sinh(|x|) = h * ( t + t/(t+1) ),   sign on x

   which equals h*(e^|x| - e^-|x|) exactly (t+t/(t+1) = (t^2+2t)/(t+1) =
   (e^|x|-1)(e^|x|+1)/e^|x|). Two hazards, both dissolved, ZERO selects (beyond
   expm1's own inherited round-bias select):

     * NEAR 0: using expm1 (not exp) keeps the leading term; and this reconstruction
       is a PURE ADDITION t + t/(t+1) (both terms > 0, NO cancellation), so it is
       well-conditioned near 0 — unlike openlibm's own |x|<1 form 2t - t^2/(t+1),
       which subtracts. t = expm1(|x|) is accurate near 0 (no e^x-1 cancellation).
     * OVERFLOW: t/(t+1) is bounded by 1, so for large t the sum is ~ t (no new
       overflow) and h*t = e^|x|/2 = sinh — valid right up to expm1's domain edge
       ln(DBL_MAX). The naive 2t - t^2/(t+1) would form t^2 and overflow.

   It CALLS `expm1` — resolved by the census closure-link to the authored
   branchless/expm1.c (indexed first) and inlined (the L2-closure spine, identical
   to how tanh calls expm1). sinh is odd; the sign rides a final copysign. fabs/
   copysign are the hardware keep-set leaves. NO tables, NO control flow.

   The e2e golden twin is tests/e2e/slice_branchless_sinh.c (same body, with expm1
   inlined as the static `bexpm1` helper) — keep the three textually in sync
   (bexpm1 == branchless/expm1.c).

   Domain: finite x with |x| <= ln(DBL_MAX) ~ 709.78 (expm1's valid range; sinh
   itself overflows to +-inf near |x| > 710.48 anyway). Beyond that, and inf/NaN,
   are UNSPECIFIED — the branchy special cases this body omits. +-0 -> +-0
   (copysign preserves the sign). Verified NaN-free on [-30,30] and the large band
   [700, 709.7] (expm1's half-scale fix keeps the n=1024 band clean — see
   branchless/expm1.c), worst <=2.7 true-ulp (observed ~2.64, peak near x~0.008) vs host long-double sinhl (near 0;
   ~0.81 ulp in the large band), correct odd symmetry (metric: |g-ref|/ulp(ref);
   the branchless expm1 leaf, ~2 ulp, dominates — a host-expm1 sweep understates
   this).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
extern double expm1(double);

double sinh(double x) {
    double t = expm1(__builtin_fabs(x));                 /* e^|x| - 1, no cancel  */
    double z = 0.5 * (t + t/(t + 1.0));                  /* = sinh(|x|), no OVF   */
    return __builtin_copysign(z, x);                     /* keep-set leaf; odd fn */
}
