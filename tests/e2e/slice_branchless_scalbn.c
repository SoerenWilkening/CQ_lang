/* slice_branchless_scalbn.c — bd 3c6m.43 / L1: a source-injected libm fn (Rule 18),
   landed by the L1 branchless-authored body spine. A BRANCHLESS soft-scalbn is
   authored inline, so clang -O1 inlines it to stock reversible OPCODES and the taint
   pass lowers those (no per-fn cq_template_scalbn).

   openlibm's s_scalbn.c handles the whole exponent range with two-stage 2^1023
   rescales guarded by data-dependent branches on n — the tainted control flow the
   census flags. This body dissolves them with the direct INSERT_WORDS scale:

       scalbn(x, n) = x * 2^n,   2^n = bitcast( (long long)(n + 1023) << 52 )

   n is a CLASSICAL int (only the double x is taintable), so the exponent word is built
   from classical operands and the single tainted op is one fmul `x * scale`. ZERO
   selects. The probe pins n = 2, so 2^n const-folds to 4.0 and the trace is the pure
   `x * 4.0` value-embedding.

   Domain: finite x and n with n + 1023 a valid biased exponent. Large-|n| octaves
   (subnormal/overflow, the openlibm two-stage rescale) are UNSPECIFIED. On the
   contractual range 2^n is exact, so x * 2^n is one correctly-rounded multiply;
   a trace-only runtime, so classical ulp is a SANITY check — scalbn(0.5, 2) = 2.0.

   The corpus twin is tools/library_coverage/branchless/scalbn.c (same body, `scalbn`
   here inlined as the static `bscalbn` helper) — keep the two textually in sync. */
static double bscalbn(double x, int n) {
    long long bits = (long long)(n + 1023) << 52;      /* 2^n exponent field      */
    double scale;
    __builtin_memcpy(&scale, &bits, 8);                /* bitcast i64->f64        */
    return x * scale;                                  /* x * 2^n                 */
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bscalbn(q, 2));
}
int main(void) { (void) slice(); return 0; }
