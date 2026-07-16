/* spec_twoarm_caller.c — the CQ translation unit for the Phase 6 / issue 5po2 I1
   golden: a plain C if/else with two DERIVED arms lifted into a reversible
   quantum clone. Mirrors spec_select_caller's quantum core (theta -> helper ->
   phase -> measure) but the helper `helper` (spec_twoarm_lib.c) if-converts to a
   two-arm integer `select(icmp sgt b,5, (b<<2)^9, (b+100)*3)`.

   Because `b` is TAINTED when it reaches `helper(b)`, the specializer lifts
   `helper` into `__cq_q_helper_1`, emits the two-arm merge as the 4.4 controlled-
   XOR two-copy stream, and Bennett-wraps it (compute the two derived arms ->
   flag mint -> copy_T/¬flag-bracket/copy_F -> copy-out -> reverse-play every
   `_unc` -> free all scratch). The borrowed quantum input `b` is preserved
   (read-only) and left allocated (a safe leak, Rule 6) — never freed dirty. This
   is the ONLY layer that LINK-proves @__cq_q_helper_1 + cqrt_copy_i32_controlled
   + the derived-arm producer `_unc` twins resolve and signature-match across
   llvm-link. `helper` is DECLARED (not defined) here, so opt sees an un-inlined
   callee body (Rule 9). */
int helper(int b);

int slice(void) {
    int b = 3;
    b = cq_theta(b, 0.5);
    int a = helper(b);
    a = cq_phi(a, 3.14);
    int z = cq_measure(a);
    return z;
}

int main(void) { (void) slice(); return 0; }
