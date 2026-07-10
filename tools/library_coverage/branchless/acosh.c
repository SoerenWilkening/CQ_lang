/* branchless/acosh.c — bd 3c6m.18 (libm L2-closure): the AUTHORED branchless
   acosh body the census injects for `acosh` (Rule 18 source injection; owner
   body-source decision 2026-07-10 = hand-author per fn, the slice_branchless_exp
   model). This file SHADOWS openlibm's branchy e_acosh.c in the census index.

   openlibm's acosh branches on x into three ranges (x near 1 / x<2 / x large — the
   L6/L2 blocker at e_acosh.c:54) to avoid BOTH the near-1 cancellation of x*x-1 AND
   the large-x overflow of x*x. This branchless body dissolves both with one
   overflow-safe, cancellation-free identity:

       acosh(x) = log(x + sqrt(x*x-1)) = log1p( (x-1) + sqrt(x-1)*sqrt(x+1) )

   Two wins in one line, ZERO selects, zero control flow:
     * sqrt(x*x-1) is computed as sqrt(x-1)*sqrt(x+1). Splitting the product across
       two sqrts HALVES each factor's exponent (each ~ sqrt(x) ~ 1e154 at x=DBL_MAX),
       so THE SQRT never overflows — sqrt(x*x-1) as a single expression would
       overflow for x > 1.34e154, but this form keeps `s` finite through DBL_MAX. It
       also kills the near-1 cancellation: x-1 is exact (Sterbenz) and x+1 ~ 2, so no
       `x*x - 1` catastrophic subtraction near x=1. (The subsequent SUM (x-1)+s ~ 2x
       still overflows for x > DBL_MAX/2 — see Domain; the sqrt split relocates the
       overflow to that last octave, matching branchless/asinh.c's identical edge.)
     * log1p (not log) keeps the near-1 accuracy: for x -> 1+ the summed argument
       (x-1)+sqrt(...) -> 0, and log1p(small) is well-conditioned where log(1+small)
       is not. It CALLS `log1p` — resolved by the census closure-link to the
       authored branchless/log1p.c (indexed first) and inlined (the L2-closure
       spine, mirrors tanh->expm1). sqrt is the hardware keep-set leaf.

   The e2e golden twin is tests/e2e/slice_branchless_acosh.c (same body, with
   log1p inlined as the static `blog1p` helper) — keep the two textually in sync.

   Domain: 1 <= x <= DBL_MAX/2 (~8.99e307). x < 1 is UNSPECIFIED — sqrt(x-1) of a
   negative gives NaN (the mathematically correct "acosh below 1 is complex", but
   not contractual). x > DBL_MAX/2 is UNSPECIFIED — the sum (x-1)+s ~ 2x overflows
   to +inf and the branchless log1p leaf returns NaN (true acosh ~ 710 is finite up
   to DBL_MAX; this is the same last-octave overflow branchless/asinh.c documents,
   the extreme-tail branch this body omits). inf/NaN inputs likewise. acosh(1) = 0
   exactly. Verified NaN-free on [1, 8.99e307], worst <=4.0 true-ulp (observed ~3.97) vs host
   long-double acoshl (metric: |g-ref|/ulp(ref); near-1 cancellation zone; only 0.47
   ulp in the 1e150..8.9e307 tail; the branchless log1p leaf, ~2 ulp, dominates —
   a host-log1p sweep understates this).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
extern double log1p(double);

double acosh(double x) {
    double t = x - 1.0;                                  /* exact (Sterbenz) near 1 */
    double s = __builtin_sqrt(t) * __builtin_sqrt(x + 1.0); /* = sqrt(x*x-1), no OVF */
    return log1p(t + s);                                 /* = log(x + sqrt(x*x-1))  */
}
