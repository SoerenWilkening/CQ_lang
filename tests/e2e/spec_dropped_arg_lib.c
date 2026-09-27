/* spec_dropped_arg_lib.c — the CLASSICAL library TU for the bd
   test_C_libtooling-vsfp goldens (slice_spec_dropped_arg_boolsel.c,
   slice_spec_dropped_arg_inplace.c). Compiles WITHOUT the CQ.h intrinsic surface
   (C18 — run_slice_multi.sh applies `-include CQ.h` to the CQ TU only); the
   tripwire below fails LOUDLY at compile if the harness ever force-includes CQ.h
   into a lib TU.

   `h` IGNORES its first argument: its parameter `a` has NO USES after `clang -O1`.
   Before bd vsfp a caller handing it a quantum value built a Phase-6 clone that
   never read that slot while the call still READ the operand, which kept a
   which-path rail the hand-inlined twin never computes alive and entangled
   (silent dephasing). `dropDeadCallArguments` now replaces the operand by `0`
   before any stage reads it, so the caller lowers to its twin's stream. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int h(int a, int k) {
    (void) a;
    return k + 1;
}
