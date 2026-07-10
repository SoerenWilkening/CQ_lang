/* branchless/atanh.c — bd 3c6m.23 (libm L2-closure): the AUTHORED branchless
   atanh body the census injects for `atanh` (Rule 18 source injection; owner
   body-source decision 2026-07-10 = hand-author per fn, the slice_branchless_exp
   model). This file SHADOWS openlibm's branchy e_atanh.c in the census index.

   openlibm's atanh branches on |x| into three ranges (|x|<2^-28 tiny / |x|<0.5 /
   0.5<=|x|<1 — the L6/L2 blocker at e_atanh.c:52) to pick a cancellation-free
   reconstruction. This branchless body keeps openlibm's OWN 0.5<=|x|<1 kernel and
   makes it valid for ALL |x|<1 with the EXACT algebraic identity

       atanh(x) = 0.5 * ln((1+x)/(1-x)) = 0.5 * log1p( 2|x| / (1-|x|) ),  sign on x

   (1 + 2|x|/(1-|x|) = (1+|x|)/(1-|x|), so the log1p folds to the atanh log). It
   CALLS `log1p` — resolved by the census closure-link to the authored
   branchless/log1p.c (indexed first) and inlined, so atanh injects as pure
   straight-line opcodes (the L2-closure spine, mirrors tanh->expm1). NO tables,
   NO control flow, NO scratch memory; ZERO selects.

   *** WORK ON |x|, NOT x — LOAD-BEARING FOR CORRECTNESS, not just symmetry. ***
   atanh is odd, so the sign rides a final copysign. But the reduction MUST run on
   ax=|x|: with a signed x, for x -> -1+ the argument 2x/(1-x) -> -1+, and log1p is
   catastrophically ill-conditioned near -1 (d/du log1p = 1/(1+u) -> +inf), so a
   ~0.5-ulp rounding of 2x/(1-x) blows up to tens of thousands of ulp (measured
   52782 ulp at x=-0.999999). Working on ax makes the argument 2ax/(1-ax) always
   >= 0 (-> +inf as ax->1), where log1p is well-conditioned; the sign is restored
   losslessly by copysign. This mirrors openlibm's `x = fabs(x)` first step.

   The e2e golden twin is tests/e2e/slice_branchless_atanh.c (same body, with
   log1p inlined as the static `blog1p` helper) — keep the two textually in sync.

   Domain: |x| < 1. |x| >= 1 is UNSPECIFIED — the branchy special cases this body
   omits: at x = +-1 the argument 2ax/(1-ax) -> +inf and the branchless log1p leaf
   returns NaN there (not the mathematical +-inf); for |x| > 1 the argument is a
   large finite negative and the branchless log1p leaf returns a finite garbage
   value (not NaN). Only |x| < 1 is contractual. +-0 -> +-0 (copysign preserves the
   sign). Verified NaN-free on (-1,1); worst <=2.5 true-ulp (observed ~2.45) vs host long-double
   atanhl (metric: |g-ref|/ulp(ref); the branchless log1p leaf, ~2 ulp, dominates —
   a host-log1p sweep understates this). The odd-fn copysign makes the two
   half-lines bit-symmetric.

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
extern double log1p(double);

double atanh(double x) {
    double ax = __builtin_fabs(x);                       /* odd fn: work on |x|   */
    double t  = 2.0 * ax / (1.0 - ax);                   /* >= 0, log1p well-cond */
    return __builtin_copysign(0.5 * log1p(t), x);        /* keep-set leaf; odd fn */
}
