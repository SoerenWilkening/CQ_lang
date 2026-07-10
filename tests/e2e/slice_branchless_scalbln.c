/* slice_branchless_scalbln.c — bd 3c6m.42 / L1: a source-injected libm fn (Rule 18),
   landed by the L1 branchless-authored body spine. scalbln is scalbn with a `long`
   exponent — the BODY is IDENTICAL (== branchless/scalbn.c), only classical `n`
   widens to long. A BRANCHLESS soft-scalbln is authored inline, so clang -O1 inlines
   it to stock reversible OPCODES and the taint pass lowers those (no per-fn template).

   openlibm's s_scalbln.c handles the exponent range with two-stage 2^1023 rescales
   guarded by data-dependent branches on n — the tainted control flow the census
   flags. This body dissolves them with the direct INSERT_WORDS scale:

       scalbln(x, n) = x * 2^n,   2^n = bitcast( (long long)(n + 1023) << 52 )

   n is a CLASSICAL long (only the double x is taintable), so the single tainted op is
   one fmul `x * scale`. ZERO selects. The probe pins n = 2, so 2^n const-folds to 4.0
   and the trace is the pure `x * 4.0` value-embedding.

   Domain: finite x and n with n + 1023 a valid biased exponent. Large-|n| octaves are
   UNSPECIFIED. On the contractual range 2^n is exact; a trace-only runtime, so
   classical ulp is a SANITY check — scalbln(0.5, 2) = 2.0.

   The corpus twin is tools/library_coverage/branchless/scalbln.c (same body, `scalbln`
   here inlined as the static `bscalbln` helper) — keep the two textually in sync. */
static double bscalbln(double x, long n) {
    long long bits = (long long)(n + 1023) << 52;      /* 2^n exponent field      */
    double scale;
    __builtin_memcpy(&scale, &bits, 8);                /* bitcast i64->f64        */
    return x * scale;                                  /* x * 2^n                 */
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bscalbln(q, 2));
}
int main(void) { (void) slice(); return 0; }
