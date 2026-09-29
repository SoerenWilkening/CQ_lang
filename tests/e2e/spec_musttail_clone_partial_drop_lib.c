/* spec_musttail_clone_partial_drop_lib.c — the CLASSICAL library TU for
   slice_spec_musttail_clone_partial_drop.c (bd ev3m + m5pn, probe `ev7`). Compiles WITHOUT the
   CQ.h intrinsic surface (C18). `h2` reads `a` only in the condition of an arm that reads a
   never-stored internal volatile global (the fenv global fold empties it) and reads `b`. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

static volatile int K = 7;

__attribute__((noinline)) int h2(int a, int b, int k) {
    if (a > 3)
        (void)K;
    return k + b;
}

int h(int a, int b, int k) {
    __attribute__((musttail)) return h2(a, b, k);
}
