/* specialize_intrinsic_caller.c — the CQ translation unit for the Phase 7.1-E
   follow-up golden (test_C_libtooling-mvjc): a curated reversible llvm.* idiom
   intrinsic INSIDE a call-graph-specialized clone. Mirrors specialize_caller.c —
   a tainted value routed through a classical library helper — but the helper's
   body now contains `__builtin_popcount` (`@llvm.ctpop.i32`, a curated Class-2
   op) rather than plain arithmetic.

   Because `x` is TAINTED when it reaches `popcount_helper(x)`, the specializer
   lifts the helper into the reversible clone `__cq_q_popcount_helper_1`
   (Bennett compute-copy-uncompute). The clone forward-computes the ctpop to the
   FROZEN `cq_template_ctpop_i32` producer, copies out only the i32 result, then
   reverses the ctpop via its void `_unc` twin (recompute-from-live-source) and
   the add via its own `_unc`, freeing each scratch rail AFTER the complete
   reverse. `y` is the basis copy the clone returns; the borrowed quantum input
   `x` is preserved read-only.

   This is the ONLY layer that LINK-proves @__cq_q_popcount_helper_1 +
   cq_template_ctpop_i32 + cq_template_ctpop_i32_unc resolve and signature-match
   across llvm-link (Rule 2, Rule 16). `popcount_helper` is DECLARED (not defined)
   here, so opt sees an un-inlined visible body only after the lib is linked in
   (Rule 9). */
int popcount_helper(int a);

int slice(void) {
    int x = 5;
    cq_theta(&x, 0.5);
    int y = popcount_helper(x);
    int z = cq_measure(y);
    return z;
}

int main(void) { (void) slice(); return 0; }
