/* spec_lift_classical_lib.c — the CLASSICAL library TU for the bd
   test_C_libtooling-d88e goldens (slice_spec_lift_scrubbed_elsewhere.c). Compiles
   WITHOUT the CQ.h intrinsic surface (C18 — run_slice_multi.sh applies
   `-include CQ.h` to the CQ TU only); the tripwire below fails LOUDLY at compile if
   the harness ever force-includes CQ.h into a lib TU.

   `h` returns `k + 1`, a CLASSICAL value: handed a TAINTED first argument, the
   specializer lifts it into `__cq_q_h_01`, proves the clone's return CLASSICAL, and
   `specialize()` scrubs the call result's conservative taint — the scrub bd d88e's
   re-ask (`declineFalsifiedMergePhiLifts`) exists to observe.

   ⚠ bd test_C_libtooling-vsfp (2026-09-26) — WHY `a` IS STORED TO A VOLATILE LOCAL.
   This body used to be `(void) a; return k + 1;`, i.e. `a` had NO USES, and bd
   vsfp's `dropDeadCallArguments` now replaces such an argument by `0` before
   `detectSpecializations` (what `clang -O1` does to the hand-inlined twin) — so
   that spelling is no Phase-6 site at all and this golden would scrub nothing. The
   volatile store keeps `a` USED in the body, so the call is still specialized; the
   clone's own lowering erases the store (the fenv ruling), the built clone never
   reads `a`, and the operand is `q`, a `cq_theta` result — the one operand bd vsfp's
   `declinePhantomCloneArgReads` exempts (a user register the phantom read neither
   mints nor keeps alive). It is the C-reachable spelling of the population the d88e
   re-ask still guards. The golden is byte-identical to the pre-vsfp one (measured). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int h(int a, int k) {
    volatile int z = a;
    return k + 1;
}
