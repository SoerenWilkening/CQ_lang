/* specialize_multiarg_caller.c — the CQ TU for the Phase 6.2 call-graph-
   specialization golden (test_C_libtooling-mvna.8, WI-2.6: signatures / cache /
   multiplicity). Routes one theta-tainted value `x` through the separate-TU
   classical helper `combine` (declared here, defined in specialize_multiarg_lib.c)
   at THREE call sites:
     r1 = combine(x, k)  — mask 0b01, arg0 quantum   → clone __cq_q_combine_01
     r2 = combine(k, x)  — mask 0b10, arg1 quantum   → clone __cq_q_combine_10
     r3 = combine(x, k)  — mask 0b01 again           → CACHE HIT, reuses _01
   So the specializer synthesizes exactly TWO distinct clones (distinct masks)
   and shares the first across the repeated site (the (callee,mask) cache). Each
   clone is Bennett-wrapped (compute → cqrt_copy_i32 → reverse-play → free) and
   returns a basis-valued copy the user measures; the borrowed quantum input `x`
   is read-only-preserved and left allocated (a Rule-6 safe leak). `combine` is
   DECLARED (not defined) here, so it is a direct call to a visible body only
   after llvm-link pulls in the lib — opt sees an un-inlined callee (Rule 9). */
int combine(int a, int b);

int slice(void) {
    int x = 3;
    cq_theta(&x, 0.5);
    int k = 5;
    int r1 = combine(x, k);
    int r2 = combine(k, x);
    int r3 = combine(x, k);
    int s = cq_measure(r1);
    s += cq_measure(r2);
    s += cq_measure(r3);
    return s;
}

int main(void) { (void) slice(); return 0; }
