/* spec_dropped_arg_musttail_lib.c — the CLASSICAL library TU for the bd vsfp ROUND-6 golden
   slice_spec_dropped_arg_musttail_inner.c (bd test_C_libtooling-w7nm; Rule-13 r5 F-Z-1, probe
   `mt1`). Compiles WITHOUT the CQ.h intrinsic surface (C18); the tripwire below fails LOUDLY at
   compile if the harness ever force-includes CQ.h into a lib TU.

   `h` forwards its first argument through a `musttail` call to `h2`, whose only read of it is the
   condition of an arm that reads a never-stored internal volatile global (the fold empties the
   arm, so `h2`'s clone records the slot dead). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

static volatile int K = 7;

__attribute__((noinline)) int h2(int a, int k) {
    if (a > 3)
        (void)K;
    return k + 1;
}

int h(int a, int k) {
    __attribute__((musttail)) return h2(a, k);
}
