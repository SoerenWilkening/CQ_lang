/* spec_lift_classical_lib.c — the CLASSICAL library TU for the bd
   test_C_libtooling-d88e goldens (slice_spec_lift_scrubbed_elsewhere.c). Compiles
   WITHOUT the CQ.h intrinsic surface (C18 — run_slice_multi.sh applies
   `-include CQ.h` to the CQ TU only); the tripwire below fails LOUDLY at compile if
   the harness ever force-includes CQ.h into a lib TU.

   `h` returns `k + 1`, a CLASSICAL value: handed a TAINTED first argument, the
   specializer lifts it into `__cq_q_h_01`, proves the clone's return CLASSICAL, and
   `specialize()` scrubs the call result's conservative taint — the scrub bd d88e's
   re-ask (`declineFalsifiedMergePhiLifts`) exists to observe.

   ⚠ bd test_C_libtooling-vsfp — WHY `a` IS STORED TO A VOLATILE LOCAL, AND WHAT
   THAT NO LONGER BUYS (round 2, 2026-09-26). This body used to be `(void) a; return
   k + 1;`. Round 1's dead-argument drop replaced an `a` with no uses by `0`, so round
   1 stored `a` to a volatile local to keep the call a Phase-6 site, and said the
   CLONE's lowering erased the store. That attribution was WRONG (bd vsfp Rule-13 r1B
   F-VB-3): the MODULE fenv pre-pass `eraseDeadVolatileScalarStores` erases it on
   THIS body, before `detectSpecializations`. Round 2 asks the drop again right after
   the fenv stages (slot B), so `a` is dead there and the call becomes `h(0, m)`: this
   golden no longer reaches the specializer or the scrub at all. It is now the e2e
   golden of the slot-B drop with a `cq_theta` operand; its bytes did not move
   (measured — the stream was already the twin's), and the spurious lyyf-(B) warning
   and dirty-rail census count bd jr8q names are gone from it (no clone call). The
   d88e lift-then-scrub re-ask has NO C-reachable member any more: a callee that READS
   its argument and returns classical needs a read that survives `clang -O1` and the
   fenv stages yet dies in the clone, which only hand-written IR provides (the
   branch-only read in the re-spelled `lowering_*_spec_scrubbed_*` lit fixtures). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int h(int a, int k) {
    volatile int z = a;
    return k + 1;
}
