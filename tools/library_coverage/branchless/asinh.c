/* branchless/asinh.c — bd 3c6m.20 (libm L2-closure): the AUTHORED branchless
   asinh body the census injects for `asinh` (Rule 18 source injection; owner
   body-source decision 2026-07-10 = hand-author per fn, the slice_branchless_exp
   model). This file SHADOWS openlibm's branchy s_asinh.c in the census index.

   openlibm's asinh branches on |x| into four ranges (|x|<2^-28 / |x|<2 / |x|<2^28 /
   |x| huge — the L6/L2 blocker at s_asinh.c:49) to avoid BOTH the near-0
   cancellation of log(1+small) AND the large-|x| overflow of x*x. This branchless
   body dissolves both with ONE overflow-safe, cancellation-free identity:

       asinh(x) = log(|x| + sqrt(x*x+1)) = log1p( |x| + (sqrt(x*x+1) - 1) ),  sign x

   ZERO control flow. Two hazards, two branchless fixes:

   *** OVERFLOW: sqrt(x*x+1) has no real product factorization (unlike acosh), so it
   is computed overflow-safe via fmin of the two complementary forms:
       s = fmin( sqrt(ax*ax + 1),  ax*sqrt(1 + 1/(x*x)) )   == sqrt(x*x+1).
   The naive sqrt(ax*ax+1) overflows for ax > 1.34e154 (ax*ax -> +inf); the
   reciprocal ax*sqrt(1+1/(x*x)) is exact there (1/inf = 0 -> ax) but is NaN at
   ax=0 (0*inf) and inf for ax below the x*x-underflow floor. fmin composes them:
   IEEE fmin(finite, NaN)=finite and fmin(finite, +inf)=finite, so fmin always
   picks the correct finite arm — s is right at 0, tiny, mid, AND the whole large
   tail (correct through DBL_MAX/2 ~ 8.99e307; only the last octave |x| > DBL_MAX/2
   overflows in the final |x|+correction sum, an extreme edge). fmin/sqrt are
   hardware keep-set leaves; there is NO select.

   *** NEAR-0: sqrt(x*x+1) rounds to exactly 1.0 for ax < 1.5e-8 (x*x < ulp(1)), so
   the naive `s - 1` drops the x^2/2 term that must survive to cancel log1p's
   -A^2/2 (else asinh(1e-8) returns log1p(1e-8) = 9.9999995e-9, ~2.3e7 ulp wrong).
   The correction is instead computed as ax*(ax/(1+s)) == ax^2/(1+s) == sqrt(x*x+1)-1
   with the DIVISION FIRST: ax/(1+s) is bounded by 1 (no overflow) yet -> ax/2 near
   0, so ax*(ax/2)=ax^2/2 is preserved. (No -ffast-math, so clang keeps the
   div-before-mul order; a reassociation to (ax*ax)/(1+s) would reintroduce the
   overflow.)

   It CALLS `log1p` — resolved by the census closure-link to the authored
   branchless/log1p.c (indexed first) and inlined (the L2-closure spine, mirrors
   tanh->expm1). asinh is odd, so the sign rides a final copysign.

   The e2e golden twin is tests/e2e/slice_branchless_asinh.c (same body, with
   log1p inlined as the static `blog1p` helper) — keep the two textually in sync.

   Domain: finite x with |x| <= DBL_MAX/2 (~8.99e307). Above that the |x|+correction
   sum overflows to +inf and the branchless log1p leaf returns NaN (true asinh ~ 710
   is finite up to DBL_MAX) — UNSPECIFIED, the extreme-tail branch this body omits;
   inf/NaN inputs likewise. +-0 -> +-0 (copysign preserves the sign). Verified
   NaN-free on [-100,100] and [1,1e154]; near 0 the div-first correction preserves
   the x^2/2 term so asinh(x) ~ x (NOT the ~2e7-ulp collapse of a naive `s-1` that
   rounds to 0). Worst <=2.1 true-ulp (observed ~2.05) vs host long-double asinhl (metric:
   |g-ref|/ulp(ref); accuracy bounded by the branchless log1p leaf, ~2 ulp — a
   host-log1p sweep understates this and shows near-0 as bit-exact).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
extern double log1p(double);

double asinh(double x) {
    double ax = __builtin_fabs(x);                       /* odd fn: work on |x|   */
    double s  = __builtin_fmin(__builtin_sqrt(ax*ax + 1.0),   /* = sqrt(x*x+1),   */
                               ax * __builtin_sqrt(1.0 + 1.0/(x*x))); /* overflow-safe */
    double A  = ax + ax*(ax/(1.0 + s));                  /* = |x| + (sqrt(x*x+1)-1) */
    return __builtin_copysign(log1p(A), x);              /* keep-set leaf; odd fn   */
}
