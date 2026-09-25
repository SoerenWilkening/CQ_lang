/* spec_lift_classical_lib.c — the CLASSICAL library TU for the bd
   test_C_libtooling-d88e goldens (slice_spec_lift_scrubbed_elsewhere.c). Compiles
   WITHOUT the CQ.h intrinsic surface (C18 — run_slice_multi.sh applies
   `-include CQ.h` to the CQ TU only); the tripwire below fails LOUDLY at compile if
   the harness ever force-includes CQ.h into a lib TU.

   `h` IGNORES its first argument and returns `k + 1`: handed a TAINTED first
   argument, the specializer lifts it into `__cq_q_h_01`, proves the clone's return
   CLASSICAL, and `specialize()` scrubs the call result's conservative taint — the
   scrub bd d88e's re-ask (`declineFalsifiedMergePhiLifts`) exists to observe. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int h(int a, int k) {
    (void) a;
    return k + 1;
}
