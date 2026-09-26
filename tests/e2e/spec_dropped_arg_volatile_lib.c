/* spec_dropped_arg_volatile_lib.c — the CLASSICAL library TU for the bd
   test_C_libtooling-vsfp ROUND-2 golden slice_spec_dropped_arg_volatile_char.c (bd
   test_C_libtooling-a8q5; Rule-13 r1B F-VB-1, probe `v15vc`). Compiles WITHOUT the
   CQ.h intrinsic surface (C18); the tripwire below fails LOUDLY at compile if the
   harness ever force-includes CQ.h into a lib TU.

   `h` stores its first argument to a `volatile char` local and never reads it. Under
   the fenv ruling (CLAUDE.md "Scope of the semantic model") the store is not
   observable, so the program MEANS the one without that line. The fenv pre-pass
   erases the store; before bd vsfp round 2 the `trunc` feeding it survived, the
   parameter still "had a use", and the caller's 4.4 `%out` which-path rail stayed
   alive across the later Ry — silent dephasing. Round 2 deletes the dead cone with
   the store and asks the dead-argument drop again right after (slot B). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int h(int a, int k) {
    volatile char z = a;
    return k + 1;
}
