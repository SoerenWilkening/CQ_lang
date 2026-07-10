/* branchless/scalbn.c — bd 3c6m.43 (libm L1): the AUTHORED branchless scalbn body
   the census injects for `scalbn` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model). This
   file SHADOWS openlibm's branchy s_scalbn.c in the census symbol index.

   *** WHY openlibm's scalbn DECLINES. *** openlibm's s_scalbn.c handles the whole
   exponent range with two-stage 2^1023 rescales guarded by data-dependent branches
   on n (the L4/L6 tainted control flow the census flags). This body dissolves those
   with the direct INSERT_WORDS scale (the same 2^n construction the branchless exp
   leaf uses for its final scale):

       scalbn(x, n) = x * 2^n,   2^n = bitcast( (long long)(n + 1023) << 52 )

   n is a CLASSICAL int (only arg0 `x` is a taintable double — the census taints just
   the double), so the exponent word is built entirely from classical operands and
   the single tainted op is one fmul `x * scale`. ZERO selects, zero control flow.

   The e2e golden twin is tests/e2e/slice_branchless_scalbn.c (same body, inlined as
   the static `bscalbn` helper) — keep the two textually in sync.

   Domain: finite x and n with n + 1023 a valid biased exponent (roughly |n| within
   the normal range). Large |n| that would need the openlibm two-stage rescale
   (subnormal/overflow octaves) is UNSPECIFIED — the branchy special cases this
   branchless body deliberately omits. On the contractual range 2^n is exact, so
   x * 2^n is a single correctly-rounded multiply (openlibm's own result).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
double scalbn(double x, int n) {
    long long bits = (long long)(n + 1023) << 52;      /* 2^n exponent field      */
    double scale;
    __builtin_memcpy(&scale, &bits, 8);                /* bitcast i64->f64        */
    return x * scale;                                  /* x * 2^n                 */
}
