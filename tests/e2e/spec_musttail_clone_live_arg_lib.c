/* spec_musttail_clone_live_arg_lib.c — the CLASSICAL library TU for slice_spec_musttail_clone_live_arg.c
   (bd m5pn, probe `mtl`). Compiles WITHOUT the CQ.h intrinsic surface (C18); the tripwire below fails
   LOUDLY at compile if the harness ever force-includes CQ.h into a lib TU. `h` forwards a READ
   argument through `musttail`. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

__attribute__((noinline)) int h2(int a, int k) {
    return k + a;
}

int h(int a, int k) {
    __attribute__((musttail)) return h2(a, k);
}
