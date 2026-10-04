/* slice_branchless_fdim.c — bd 3c6m.16 / L1: a source-injected libm fn (Rule 18),
   landed by the L1 branchless-authored body spine. A BRANCHLESS soft-fdim is authored
   inline, so clang -O1 inlines it to stock reversible OPCODES and the taint pass
   lowers those (no per-fn cq_template_fdim).

   openlibm's s_fdim.c branches on isnan and `x <= y ? 0 : x - y` — the tainted control
   flow the census flags. fdim is the positive difference, exactly a keep-set fmax over
   the difference:

       fdim(x,y) = (x > y) ? x - y : 0   ==   fmax(x - y, 0.0)

   ONE fsub + ONE @llvm.maxnum (fmax hardware-kept, Rule 18) — NO selects, NO branches.
   3c6m.48: each taint mask is a distinct unitary with its own golden; this pins (q,c)
   — x = q tainted, y = 0.5 const (the qc mask, `x - 0.5` then fmax with 0). Siblings
   slice_branchless_fdim_{cq,qq}.c pin (c,q) and (q,q).

   Domain: all finite x,y (fdim is total — no division/cancellation hazard; the fmax
   clamp keeps the result finite and >= 0). Extreme-octave overflow of x - y is
   UNSPECIFIED. A trace-only runtime, so classical ulp is a SANITY check — fdim(0.5,0.5)
   = 0. The corpus twin is tools/library_coverage/branchless/fdim.c (same body, `fdim`
   here inlined as the static `bfdim` helper) — keep the two textually in sync. */
static double bfdim(double x, double y) {
    return __builtin_fmax(x - y, 0.0);                 /* positive difference     */
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(bfdim(q, 0.5));                  /* (q,c): x tainted, y const */
}
int main(void) { (void) slice(); return 0; }
