/* slice_branchless_cbrt.c — bd 3c6m.10 / L1: a source-injected transcendental
   (Rule 18), landed by the L1 branchless-authored body spine. A BRANCHLESS
   soft-cbrt — EXACTLY FreeBSD/openlibm's s_cbrt.c algorithm (magic-constant
   bit-hack seed + degree-4 polynomial refinement + one Newton step) with ONLY
   the data-dependent special-case branches removed — is authored inline, so
   clang -O1 inlines it to stock reversible OPCODES and the taint pass lowers
   those (no per-fn cq_template_cbrt).

   Like slice_branchless_log, range reduction needs ZERO selects: the rough cbrt
   seed "divides the exponent by 3" as an integer op on the punned high word
   (hx/3 + Kahan's B1), the sign rides a bit, and the 23-bit round is a pure
   integer add+mask on the bit pattern — all straight-line. The decomposition
   round-trips BOTH p119.7 bitcast directions (f64->i64 and i64->f64), twice.

   Domain: finite NORMAL x (either sign; cbrt is odd, negatives ride the sign
   bit). x==0 / subnormal / inf / NaN give unspecified results — the branchy
   special cases this authored body deliberately omits. Accuracy is openlibm's
   own (<=1 ulp on the documented domain; verified <=1 ulp over a 20M-point
   two-sided log-magnitude sweep vs host libm, all boundary cubes exact).

   The corpus twin is tools/library_coverage/branchless/cbrt.c (same body) —
   keep the two textually in sync. */
static double bcbrt(double x) {
    const double P0 =  1.87595182427177009643;
    const double P1 = -1.88497979543377169875;
    const double P2 =  1.621429720105354466140;
    const double P3 = -0.758397934778766047437;
    const double P4 =  0.145996192886612446982;

    unsigned long long ix;
    __builtin_memcpy(&ix, &x, 8);                      /* bitcast f64->i64        */
    unsigned long long sign = ix & 0x8000000000000000ULL;             /* sign(x)   */
    unsigned int hx = (unsigned int)((ix & 0x7FFFFFFFFFFFFFFFULL) >> 32); /* |x| hi word */

    unsigned long long tbits =
        sign | ((unsigned long long)(hx / 3u + 715094163u) << 32);      /* + B1   */
    double t;
    __builtin_memcpy(&t, &tbits, 8);                   /* bitcast i64->f64        */

    double r = (t * t) * (t / x);
    t = t * ((P0 + r * (P1 + r * P2)) + ((r * r) * r) * (P3 + r * P4));

    unsigned long long ut;
    __builtin_memcpy(&ut, &t, 8);
    ut = (ut + 0x80000000ULL) & 0xFFFFFFFFC0000000ULL;
    __builtin_memcpy(&t, &ut, 8);

    double s  = t * t;
    double rr = x / s;
    double w  = t + t;
    rr = (rr - t) / (w + rr);
    return t + t * rr;
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(bcbrt(q));
}
int main(void) { (void) slice(); return 0; }
