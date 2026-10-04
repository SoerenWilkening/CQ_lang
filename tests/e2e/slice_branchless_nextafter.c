/* slice_branchless_nextafter.c — bd 3c6m.39 / L1: a source-injected libm fn (Rule 18),
   landed by the L1 branchless-authored body spine. A BRANCHLESS soft-nextafter is
   authored inline, so clang -O1 inlines it to stock reversible OPCODES and the taint
   pass lowers those (no per-fn cq_template_nextafter).

   openlibm's s_nextafter.c is a ladder of data-dependent branches (x==y early-out,
   x==0 subnormal seed, over/underflow flag raises — the L5-shadow / nested-control
   blocker). This body renders the one-ULP bit step FULLY ARITHMETIC (ZERO selects):

       dir  = (y>x) - (y<x)          # +1 toward +inf, -1 toward -inf, 0 if x==y
       step = dir * (1 - 2*sign(x))  # bit pattern moves +dir for x>=0, -dir for x<0
       nextafter(x,y) = bitcast( bits(x) + step )

   The comparisons are fcmp->zext (not selects), the sign is a bit shift, and the combine
   is integer mul/add — so every taint mask lowers as straight-line opcodes, no tainted
   control. x==y falls out (dir==0 -> step==0). 3c6m.48: this pins (q,c) — x = q tainted,
   y = 0.5 const. Siblings slice_branchless_nextafter_{cq,qq}.c pin (c,q) and (q,q).

   Domain: finite NORMAL x != 0, finite y (the ±1 bit step ripples the exponent at
   binade boundaries correctly). UNSPECIFIED: x == ±0, a NaN argument (openlibm returns
   NaN; here dir=0 so it returns x), and the DBL_MAX->+inf edge. On the contractual range
   it is EXACT (the ±1 bit step IS nextafter's definition); no in-domain NaN/Inf. A
   trace-only runtime, so this is a SANITY check.

   The corpus twin is tools/library_coverage/branchless/nextafter.c (same body,
   `nextafter` here inlined as the static `bnextafter` helper) — keep in sync. */
static double bnextafter(double x, double y) {
    unsigned long long ix;
    __builtin_memcpy(&ix, &x, 8);                      /* bitcast f64->i64        */
    long long up  = (long long)(y > x);                /* fcmp ogt -> zext (0/1)  */
    long long dn  = (long long)(y < x);                /* fcmp olt -> zext (0/1)  */
    long long dir = up - dn;                           /* +1 / -1 / 0 (value dir) */
    long long neg = (long long)(ix >> 63);             /* sign bit: 1 if x < 0    */
    long long step = dir * (1 - 2 * neg);              /* bit-pattern delta       */
    ix = ix + (unsigned long long)step;                /* one ULP toward y        */
    double out;
    __builtin_memcpy(&out, &ix, 8);                    /* bitcast i64->f64        */
    return out;
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(bnextafter(q, 0.5));             /* (q,c): x tainted, y const */
}
int main(void) { (void) slice(); return 0; }
