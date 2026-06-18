/* specialize_transitive_inner_lib.c — the LEAF classical library TU for the
   Phase 6.3 transitive golden (test_C_libtooling-mvna.9, WI-3.5). Compiles
   without the CQ.h intrinsic surface (C18); the tripwire below fails LOUDLY if
   the harness ever force-includes CQ.h here.

   `inner` is the leaf of the two-level chain: a single-op pure-classical i32
   body. Lifted under a tainted argument it becomes @__cq_q_inner_1 (the forward
   Bennett clone) plus @__cq_q_inner_1_unc (the void uncompute twin the outer
   clone's reverse calls). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int inner(int a) {
    return a * 7;
}
