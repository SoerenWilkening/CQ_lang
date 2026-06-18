/* specialize_transitive_outer_lib.c — the MIDDLE classical library TU for the
   Phase 6.3 transitive golden (test_C_libtooling-mvna.9, WI-3.5). Like every
   classical lib it MUST compile without the CQ.h intrinsic surface (C18 —
   run_slice_multi.sh applies `-include CQ.h` to the CQ TU only); the tripwire
   below fails LOUDLY at compile if the harness ever force-includes CQ.h here.

   `outer` is a VISIBLE, PURELY-CLASSICAL, NON-RECURSIVE, single-basic-block i32
   body whose ONE nested call is to another such body (`inner`, declared here,
   defined in specialize_transitive_inner_lib.c). With a tainted argument it is
   the transitive case: @__cq_q_outer_1's body holds the retargeted
   @__cq_q_inner_1 call as an ordinary forward handle op, reversed by the inner's
   uncompute twin. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int inner(int a);

int outer(int t) {
    return inner(t) + 1;
}
