/* slice_branchless_hypot.c — bd 3c6m.33 / L1: a source-injected libm fn (Rule 18),
   landed by the L1 branchless-authored body spine. A BRANCHLESS soft-hypot is authored
   inline, so clang -O1 inlines it to stock reversible OPCODES and the taint pass lowers
   those (no per-fn cq_template_hypot).

   openlibm's e_hypot.c is a ladder of exponent-word branches (scale-by-2^k, swap so
   |a|>=|b|, medium/large/tiny special cases — the nested tainted control flow the
   census flags). This body keeps the overflow-safe scaling but renders it branchless
   via the keep-set fmax/fmin:

       hi = fmax(|x|,|y|),  lo = fmin(|x|,|y|),  r = lo/hi
       hypot(x,y) = hi * sqrt(1 + r*r)

   Dividing by the LARGER magnitude keeps r in [0,1] so r*r never overflows. fabs/fmax/
   fmin/sqrt are all hardware-kept (Rule 18); NO selects, NO branches. 3c6m.48: this
   pins (q,c) — x = q tainted, y = 0.5 const. Siblings slice_branchless_hypot_{cq,qq}.c
   pin (c,q) and (q,q).

   Domain: finite x,y NOT both zero. At (0,0), hi == 0 and r = 0/0 = NaN — (0,0) is
   UNSPECIFIED (the one in-domain singularity, exactly the openlibm special case). On
   the rest of the finite plane the overflow-safe scaling keeps the result finite and it
   is openlibm's own <1-ulp value; a trace-only runtime, so classical ulp is a SANITY
   check — hypot(0.5, 0.5) = 0.5*sqrt(2). The corpus twin is
   tools/library_coverage/branchless/hypot.c (same body, `hypot` here inlined as the
   static `bhypot` helper) — keep the two textually in sync. */
static double bhypot(double x, double y) {
    double ax = __builtin_fabs(x);
    double ay = __builtin_fabs(y);
    double hi = __builtin_fmax(ax, ay);                /* larger magnitude        */
    double lo = __builtin_fmin(ax, ay);                /* smaller magnitude       */
    double r  = lo / hi;                               /* r in [0,1], no overflow */
    return hi * __builtin_sqrt(1.0 + r * r);           /* overflow-safe hypot     */
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(bhypot(q, 0.5));                 /* (q,c): x tainted, y const */
}
int main(void) { (void) slice(); return 0; }
