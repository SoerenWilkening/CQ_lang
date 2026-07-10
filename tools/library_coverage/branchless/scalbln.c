/* branchless/scalbln.c — bd 3c6m.42 (libm L1): the AUTHORED branchless scalbln body
   the census injects for `scalbln` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model). This
   file SHADOWS openlibm's branchy s_scalbln.c in the census symbol index.

   scalbln is scalbn with a `long` exponent instead of `int` — the BODY is IDENTICAL
   (branchless/scalbn.c), only the classical `n` widens to long. See scalbn.c for the
   full rationale (openlibm's two-stage 2^1023 rescale ladder is the tainted control
   flow the census flags; this body dissolves it with the direct INSERT_WORDS scale):

       scalbln(x, n) = x * 2^n,   2^n = bitcast( (long long)(n + 1023) << 52 )

   `n` is a CLASSICAL long (only arg0 `x` is a taintable double), so the exponent word
   is built from classical operands and the single tainted op is one fmul `x * scale`.
   ZERO selects, zero control flow.

   The e2e golden twin is tests/e2e/slice_branchless_scalbln.c (same body, inlined as
   the static `bscalbln` helper) — keep the two textually in sync.

   Domain: finite x and n with n + 1023 a valid biased exponent. Large |n| octaves
   (subnormal/overflow, needing the openlibm two-stage rescale) are UNSPECIFIED. On
   the contractual range 2^n is exact and x * 2^n is a single correctly-rounded
   multiply (openlibm's own result).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
double scalbln(double x, long n) {
    long long bits = (long long)(n + 1023) << 52;      /* 2^n exponent field      */
    double scale;
    __builtin_memcpy(&scale, &bits, 8);                /* bitcast i64->f64        */
    return x * scale;                                  /* x * 2^n                 */
}
