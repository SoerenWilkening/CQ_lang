/* spec_clone_read_nested_lib.c — the CLASSICAL library TU for the bd
   test_C_libtooling-rhk5 golden slice_spec_clone_read_nested.c. Compiles WITHOUT the
   CQ.h intrinsic surface (C18); the tripwire below fails LOUDLY at compile if the
   harness ever force-includes CQ.h into a lib TU.

   `h` calls a `noinline` `g`, so the Phase-6 clone of `h` holds an INNER clone call
   `__cq_q_g_1` and, in its Bennett reverse, the inner `_unc` twin `__cq_q_g_1_unc`:
   the proof that the caller's argument is only READ has to go through both.

   WHY `g(k) ^ k` AND NOT `g(k) + 1` (measured, TRACK_RHK5.md): with a classical
   immediate the hand-inlined twin's `q * 5 + 1` lowers IN PLACE (M-C `cqrt_addc`),
   which clone bodies never do (`inBennettClone`), so the two traces differ in gate
   VOCABULARY even though they are the same circuit — beyond what
   tools/trace_twin_equiv.py can witness. The Q+Q `^ k` keeps both out of place. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

__attribute__((noinline)) int g(int k) {
    return k * 5;
}

int h(int a, int k) {
    (void) a;
    return g(k) ^ k;
}
