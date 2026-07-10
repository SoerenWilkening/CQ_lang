/* slice_branchless_remainder.c — bd 3c6m.41 / L1: a source-injected libm fn (Rule 18),
   landed by the L1 branchless-authored body spine. A BRANCHLESS soft-remainder is
   authored inline, so clang -O1 inlines it to stock reversible OPCODES and the taint
   pass lowers those (no per-fn cq_template_remainder).

   openlibm's e_remainder.c calls the e_fmod bit-loop then applies a rounding correction
   under data-dependent branches (the nested tainted control flow the census flags).
   remainder differs from fmod only in round-to-nearest (not truncation) for the
   quotient, exactly the keep-set rint:

       remainder(x,y) = x - rint(x / y) * y

   rint is hardware-kept (@llvm.rint, roundsd round-to-nearest-even, Rule 18); ONE fdiv
   + rint + fmul + fsub, NO selects, NO branches. IEEE round-to-nearest-even IS rint's
   default, so the |remainder| <= |y|/2 tie-breaking matches. 3c6m.48: this pins (q,c)
   — x = q tainted, y = 0.5 const (x/0.5, `_hl` fdiv). Siblings
   slice_branchless_remainder_{cq,qq}.c pin (c,q) [0.5/q, `_lh`] and (q,q).

   Domain: finite x, finite y != 0 with |x/y| < 2^53. y == 0 and the huge-ratio octave
   are UNSPECIFIED. Exact for the common small-ratio range; a trace-only runtime, so
   classical ulp is a SANITY check — remainder(0.5, 0.5) = 0. The corpus twin is
   tools/library_coverage/branchless/remainder.c (same body, `remainder` here inlined as
   the static `bremainder` helper) — keep the two textually in sync. */
static double bremainder(double x, double y) {
    return x - __builtin_rint(x / y) * y;              /* nearest-division rem    */
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bremainder(q, 0.5));             /* (q,c): x tainted, y const */
}
int main(void) { (void) slice(); return 0; }
