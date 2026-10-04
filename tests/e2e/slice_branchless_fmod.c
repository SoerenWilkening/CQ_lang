/* slice_branchless_fmod.c — bd 3c6m.32 / L1: a source-injected libm fn (Rule 18),
   landed by the L1 branchless-authored body spine. A BRANCHLESS soft-fmod is authored
   inline, so clang -O1 inlines it to stock reversible OPCODES and the taint pass lowers
   those (no per-fn cq_template_fmod).

   openlibm's e_fmod.c is a data-dependent shift-and-subtract loop over the mantissa
   words (bounded loop + special-case branches — the nested tainted control flow the
   census flags). This body dissolves it with the truncated-quotient identity:

       fmod(x,y) = x - trunc(x / y) * y

   trunc is hardware-kept (@llvm.trunc, roundsd, Rule 18); ONE fdiv + trunc + fmul +
   fsub, NO selects, NO branches. 3c6m.48: each taint mask is a distinct unitary with
   its own golden; this pins (q,c) — x = q tainted, y = 0.5 const (x/0.5, `_hl` fdiv).
   Siblings slice_branchless_fmod_{cq,qq}.c pin (c,q) [0.5/q, `_lh` fdiv] and (q,q).

   Domain: finite x, finite y != 0 with |x/y| < 2^53 (trunc exactly representable).
   y == 0 and the huge-ratio octave (where trunc drops the low remainder bits the
   openlibm bit-loop keeps) are UNSPECIFIED. Exact for the common small-ratio range; a
   trace-only runtime, so classical ulp is a SANITY check — fmod(0.5, 0.5) = 0. The
   corpus twin is tools/library_coverage/branchless/fmod.c (same body, `fmod` here
   inlined as the static `bfmod` helper) — keep the two textually in sync. */
static double bfmod(double x, double y) {
    return x - __builtin_trunc(x / y) * y;             /* truncated-division rem  */
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(bfmod(q, 0.5));                  /* (q,c): x tainted, y const */
}
int main(void) { (void) slice(); return 0; }
