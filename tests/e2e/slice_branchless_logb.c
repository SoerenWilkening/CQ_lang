/* slice_branchless_logb.c — bd 3c6m.38 / L1: a source-injected libm fn (Rule 18),
   landed by the L1 branchless-authored body spine. A BRANCHLESS soft-logb is
   authored inline, so clang -O1 inlines it to stock reversible OPCODES and the taint
   pass lowers those (no per-fn cq_template_logb).

   openlibm's s_logb.c is a ladder of special-case branches (subnormal / 0 / inf /
   NaN) around a single exponent-field extract — the nested tainted control flow the
   census flags. This body keeps ONLY the extract:

       logb(x) = (double)( ((bits(x) >> 52) & 0x7FF) - 1023 )   [x normal]

   the unbiased binary exponent of a finite NORMAL x — pure straight-line integer +
   bitcast + sitofp opcodes, ZERO selects.

   Domain: finite NORMAL x. x==0 (openlibm -inf), subnormal, inf/NaN are UNSPECIFIED
   (this body yields the finite field-based value, never NaN/Inf on the normal range).
   Exact on normal x (the exponent field is exact); a trace-only runtime, so classical
   ulp is a SANITY check, not a gate — logb(0.5) = -1.

   The corpus twin is tools/library_coverage/branchless/logb.c (same body, `logb`
   here inlined as the static `blogb` helper) — keep the two textually in sync. */
static double blogb(double x) {
    unsigned long long bits;
    __builtin_memcpy(&bits, &x, 8);                    /* bitcast f64->i64        */
    int e = (int)((bits >> 52) & 0x7FFULL) - 1023;     /* biased exp field - bias */
    return (double)e;                                  /* sitofp i32->f64         */
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(blogb(q));
}
int main(void) { (void) slice(); return 0; }
