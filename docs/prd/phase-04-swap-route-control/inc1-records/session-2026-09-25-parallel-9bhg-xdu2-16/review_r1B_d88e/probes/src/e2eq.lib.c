/* spec_lift_quantum_lib.c — the library TU for the bd test_C_libtooling-d88e
   SPEC-QUANTUM golden (slice_spec_lift_quantum_base.c). Compiles WITHOUT the CQ.h
   intrinsic surface (C18); the tripwire below fails LOUDLY if the harness ever
   force-includes CQ.h into a lib TU.

   `h` returns `a + k`: handed a TAINTED first argument, the specializer's clone
   `__cq_q_h_01` returns a QUANTUM handle, nothing is scrubbed, and the caller's
   one-register merge-phi lift over that handle is a TRUE renaming — the re-ask
   after `specialize()` must keep it. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int h(int a, int k) {
    return a + k;
}
