/* slice_branchless_exp.c — bd 3c6m.7 / p119: the first TRANSCENDENTAL compiled by
   SOURCE INJECTION (Rule 18). A BRANCHLESS soft-exp body — select-based range
   reduction, NO tables, NO data-dependent control flow, NO scratch memory — is
   authored inline, so clang -O1 inlines it to stock reversible OPCODES and the
   taint pass lowers those (no per-fn cq_template_exp). This realizes the injection
   census's own conclusion: off-the-shelf branchy libm is blocked by nested control
   flow + scratch memory; a branchless-authored body compiles.

   It is load-bearing on BOTH p119 lowering unlocks:
     * p119.6 — `n = (int)(select-derived fp)` -> cq_template_fptosi_f64_to_i32 on
       the kjd1 fp-select merge (was: "no template for opcode fptosi i32").
     * p119.7 — the 2^n scale via INSERT_WORDS -> cq_template_bitcast_i64_to_f64
       (was: "no template for opcode bitcast i64 in tainted context").
   Plus the kjd1 fp-DATA select (cqrt_copy_f64_controlled) for the round bias. */
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
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(bexp(q));
}
int main(void) { (void) slice(); return 0; }
