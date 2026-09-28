/* spec_dropped_arg_musttail_return_lib.c — the CLASSICAL library TU for the bd ev3m golden
   slice_spec_dropped_arg_musttail_return.c (r5 `mt2` / r6 `mm1`). Compiles WITHOUT the CQ.h
   intrinsic surface (C18); the tripwire below fails LOUDLY at compile if the harness ever
   force-includes CQ.h into a lib TU.

   `h2` reads `a` only in the condition of an arm that reads a never-stored internal volatile
   global: the fenv global fold empties the arm, the arm fold removes the branch, and the
   parameter is dead before `detectSpecializations` (the drop's slot B). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

static volatile int K = 7;

__attribute__((noinline)) int h2(int a, int k) {
    if (a > 3)
        (void)K;
    return k + 1;
}
