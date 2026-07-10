/* slice_branchless_exp2.c — bd 3c6m.30 / L2-closure: a source-injected
   transcendental (Rule 18), landed by the L1 branchless-authored body spine. A
   BRANCHLESS soft-exp2 is authored inline, so clang -O1 inlines it to stock
   reversible OPCODES and the taint pass lowers those (no per-fn cq_template_exp2).

   openlibm's exp2 reduces x then reads a 256-entry accuracy table `tbl[i0]` with a
   data-dependent index (s_exp2.c:376 — the L5-qrom tainted-index const-global read
   blocker). This body dissolves the table with exp2(x) = 2^x = exp(x·ln2) and calls
   the branchless `exp` leaf (== branchless/exp.c), inlined here as the static `bexp`
   helper: select-based range reduction (ONE fp-data round-bias select — the kjd1
   accept shape), Horner exp(r) on the reduced range, 2^n scale via INSERT_WORDS. No
   table, no scratch memory.

   Domain: finite x on the representable range of 2^x. Accuracy ≈3e-6 relative worst
   case (measured 3.24e-6 — the branchless exp leaf's degree-5-Taylor truncation;
   trace-only runtime, so classical ulp is a sanity check, not a gate);
   overflow/underflow/NaN UNSPECIFIED.

   The corpus twins are tools/library_coverage/branchless/{exp2,exp}.c (same bodies;
   bexp == branchless/exp.c) — keep the three textually in sync. */

/* the branchless exp kernel, inlined (== tools/library_coverage/branchless/exp.c) */
static double bexp(double x) {
    double xn   = x * 1.4426950408889634;                 /* x / ln2                        */
    double half = (xn < 0.0) ? -0.5 : 0.5;                /* branchless round bias (select) */
    int    n    = (int)(xn + half);                       /* fptosi on select-derived fp    */
    double r    = x - (double)n * 0.6931471805599453;     /* reduced arg (sitofp back)      */
    double p    = 1.0 + r*(1.0 + r*(0.5 + r*(0.1666666666666
                     + r*(0.0416666666 + r*0.008333333)))); /* Horner exp(r) on reduced range */
    long long bits = (long long)(n + 1023) << 52;         /* 2^n exponent field             */
    double scale;
    __builtin_memcpy(&scale, &bits, 8);                   /* bitcast i64->f64 (INSERT_WORDS) */
    return p * scale;
}

static double bexp2(double x) {
    return bexp(x * 0.69314718055994530942);              /* 2^x = e^(x·ln2)                */
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bexp2(q));
}
int main(void) { (void) slice(); return 0; }
