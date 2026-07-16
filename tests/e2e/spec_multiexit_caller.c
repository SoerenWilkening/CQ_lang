/* spec_multiexit_caller.c — the CQ translation unit for the Phase 6 / issue 5po2
   I2 golden: a MULTI-EXIT controlled-return in a lifted fp80 clone (the openlibm
   `expl`-family shape; see spec_multiexit_lib.c for the lowering). Driven through
   the full multi-TU pipeline (clang -O1 per TU → llvm-link → opt cq-lowering →
   link → run; the ONLY layer that LINKS, Rule 2/16).

   The quantum core is theta → mini_expl → measure over x86_fp80. Because `x` is
   TAINTED when it reaches `mini_expl(x)`, the specializer lifts the callee (whose
   body is a multi-exit controlled-return over classical-sentinel arms) into
   `__cq_q_mini_expl_1` and Bennett-wraps it. `mini_expl` is DECLARED (not defined)
   here, so opt sees an un-inlined callee body (Rule 9). */
long double mini_expl(long double x);

long double slice(void) {
    long double x = cq_theta((long double)5.0e-1, 0.5);
    long double r = mini_expl(x);
    return cq_measure(r);
}

int main(void) { (void) slice(); return 0; }
