/* branchless/tanh.c — bd 3c6m.47 (libm L1): the AUTHORED branchless tanh body
   the census injects for `tanh` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model).
   This file SHADOWS openlibm's branchy s_tanh.c in the census symbol index.

   openlibm's tanh branches on |x| into four ranges (tiny / |x|<1 / 1≤|x|<22 /
   |x|≥22 saturate — the L6-nested-ctrl blocker at s_tanh.c:57) to pick a
   cancellation-free reconstruction. This branchless body keeps openlibm's OWN
   |x|<1 kernel — the expm1 identity that is accurate near 0 (no `exp(x)-1`
   cancellation) — and makes it valid for ALL |x| with a single keep-set clamp:

       tanh(|x|) = -t / (t + 2),   t = expm1(-2|x|)  ∈ (-1, 0]

   is exact algebra ((1-e^{-2|x|})/(1+e^{-2|x|})), well-conditioned everywhere
   (t+2 ∈ [1,2], never near 0). It calls `expm1` — resolved by the census
   closure-link to the authored branchless/expm1.c (indexed first) and inlined,
   so tanh injects as pure straight-line opcodes (mirrors openlibm's s_tanh.c,
   which likewise calls expm1). tanh is odd, so the sign rides a final copysign.

   *** SATURATION WITHOUT A BRANCH. *** openlibm's |x|≥22 branch returns ±1. The
   branchless equivalent is fmin(|x|, 20): tanh is 1.0 to full double precision
   for |x| ≥ 20 (1 - 2e^{-40} rounds to 1), so clamping |x| to 20 changes NOTHING
   below 20 and pins the answer to tanh(20)=1.0 above it. The clamp ALSO keeps
   expm1's argument in-domain: -2·min(|x|,20) ∈ [-40, 0], well inside expm1's
   valid [-708, 709.78] (a raw -2|x| would drive expm1 out of domain and return
   garbage for large |x| — the clamp is load-bearing for correctness, not just
   speed). fabs / fmin / copysign are the hardware keep-set leaves (like cbrt's
   fabs); the only non-straight-line construct is expm1's inherited round-bias fp
   select (the kjd1 accept shape). NO tables, NO control flow, NO scratch memory.

   The e2e golden twin is tests/e2e/slice_branchless_tanh.c (same body, with
   expm1 inlined as a static helper) — keep the two textually in sync.

   Domain: all finite x. tanh(±∞) is UNSPECIFIED (fabs(±∞)=∞, fmin(∞,20)=20 →
   returns ±1, which is right, but not contractually guaranteed); ±0 → ±0
   (copysign preserves the sign). Verified: |output| ≤ 1 for every input, NO
   in-domain NaN (30M-point sweep on [-25,25] + tail to 1e6), correct ±1
   saturation. Accuracy ≤3.1 ulp vs host libm (true worst ~3.05 ulp near
   |x|≈0.125, e.g. x=0.12549999999753567) — inherited from the branchless expm1
   kernel (≤1.66 ulp on [-1,0]) amplified ~1.9× by the reconstruction (feeding an
   EXACT expm1 into -t/(t+2) leaves only ~0.05 ulp, confirming the error is
   expm1's, not the reconstruction's); openlibm's tanh is tighter ONLY because its
   expm1 is <1 ulp. This ~3-ulp corner is the honest cost of reusing the
   branchless expm1 rather than a bespoke tanh minimax.

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO
   -fno-builtin (see branchless/log.c for the inliner-compatibility reason). */
extern double expm1(double);

double tanh(double x) {
    double ax  = __builtin_fabs(x);                      /* odd fn: work on |x|   */
    double axc = __builtin_fmin(ax, 20.0);               /* saturate ≥20; keep    */
                                                         /* expm1 arg ≥ -40       */
    double t   = expm1(-2.0 * axc);                      /* e^{-2|x|} - 1 ∈ (-1,0] */
    double z   = -t / (t + 2.0);                         /* = tanh(|x|)           */
    return __builtin_copysign(z, x);                     /* keep-set leaf; odd fn */
}
