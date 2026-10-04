/* specialize_caller.c — the CQ translation unit for the Phase 6.1 call-graph-
   specialization golden (test_C_libtooling-mvna.7, WI-1.11). Mirrors
   slice_theta_add_measure's quantum core (theta -> ... -> measure) but routes
   the quantum value through a classical library helper defined in the separate
   specialize_lib.c. Because `x` is TAINTED when it reaches `helper(x)`, the
   call-graph specializer lifts `helper` into the reversible clone
   `__cq_q_helper_1` (Bennett compute-copy-uncompute) and retargets the call via
   setCalledFunction; `y` is the basis-valued copy the clone returns, which the
   user then measures. The borrowed quantum input `x` is preserved (read-only)
   and left allocated (a safe leak, Rule 6) — never freed dirty.

   This is the ONLY layer that LINK-proves @__cq_q_helper_1 + cqrt_copy_i32 +
   the data-template adjoints (`_unc`) resolve and signature-match across
   llvm-link. `helper` is DECLARED (not defined) here, so it becomes a direct
   call to a visible definition only after specialize_lib.c is linked in — the
   structural guarantee that opt sees an un-inlined callee body (Rule 9). */
int helper(int a);

int slice(void) {
    int x = 3;
    cq_theta(&x, 0.5);
    int y = helper(x);
    int z = cq_measure(y);
    return z;
}

int main(void) { (void) slice(); return 0; }
