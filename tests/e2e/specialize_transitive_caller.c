/* specialize_transitive_caller.c — the CQ translation unit for the Phase 6.3
   TRANSITIVE call-graph-specialization golden (test_C_libtooling-mvna.9, WI-3.5).
   A single theta-tainted `x` is routed through a TWO-LEVEL classical call chain
   that crosses THREE translation units: `outer` (specialize_transitive_outer_lib.c)
   calls `inner` (specialize_transitive_inner_lib.c). Both are DECLARED (not
   defined) along the chain, so opt sees un-inlined bodies only after llvm-link
   (Rule 9).

   Because `x` is TAINTED at `outer(x)`, the specializer lifts `outer` into the
   reversible clone @__cq_q_outer_1; re-scanning that clone finds the inner call
   on the post-seed-tainted `t`, so it lifts `inner` into @__cq_q_inner_1 too and
   synthesizes the inner's void uncompute twin @__cq_q_inner_1_unc. The outer
   Bennett wrap's reverse calls that twin to zero the entangled inner-result rail
   before freeing it, so the borrowed quantum input `x` is restored (Rule 6/8).
   `r` is the basis-valued copy the outer clone returns, which the user measures.

   This is the ONLY layer that LINK-proves @__cq_q_outer_1 + @__cq_q_inner_1 + the
   uncompute twin @__cq_q_inner_1_unc all resolve and signature-match through
   llvm-link across the three modules. */
int outer(int t);

int slice(void) {
    int x = 3;
    cq_theta(&x, 0.5);
    int r = outer(x);
    return cq_measure(r);
}

int main(void) { (void) slice(); return 0; }
