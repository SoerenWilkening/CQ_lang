/* specialize_lib.c — the CLASSICAL library translation unit for the Phase 6.1
   call-graph-specialization golden (test_C_libtooling-mvna.7, WI-1.11). Like
   slice_multi_lib.c it must compile WITHOUT the CQ.h intrinsic surface (C18 —
   run_slice_multi.sh applies `-include CQ.h` to the CQ TU only); the tripwire
   below fails LOUDLY at compile if the harness ever force-includes CQ.h into a
   lib TU rather than silently producing a wrong artifact.

   `helper` is exactly the body Phase 6.1 accepts: a VISIBLE, PURELY-CLASSICAL,
   NON-RECURSIVE, single-basic-block i32 body — no memory, no nested call, no
   in-body control (the SpecializeReject whitelist). The caller hands it a
   TAINTED (quantum) argument, so the specializer clones it into
   `__cq_q_helper_1`, lowers the body to reversible templates, and Bennett-wraps
   it (compute -> cqrt_copy_i32 -> reverse-play -> free). Two data ops — an `_hl`
   add (handle+literal) then a `qq` mul (handle+handle) — exercise the LIFO
   reverse order AND both template-adjoint (`_unc`) shapes through llvm-link. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int helper(int a) {
    int t = a + 3;
    return t * a;
}
