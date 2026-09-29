/* spec_musttail_rhk5_window_lib.c — the CLASSICAL library TU for slice_spec_musttail_rhk5_window.c
   (bd ev3m, probe `ev9`). Compiles WITHOUT the CQ.h intrinsic surface (C18). `g` reads its first
   argument (its clone returns a quantum value); `h2` reads `a` only in a volatile-fold arm. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

static volatile int K = 7;

__attribute__((noinline)) int g(int a, int k) {
    return a + k;
}

__attribute__((noinline)) int h2(int a, int k) {
    if (a > 3)
        (void)K;
    return k + 1;
}
