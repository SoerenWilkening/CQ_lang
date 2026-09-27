/* spec_classical_return_lib.c — the plain-C library TU of e2e-spec-classical-return
   (bd test_C_libtooling-9bhg). No CQ.h: `h` ignores its first argument, so the
   Phase-6 clone of `h(q, m)` with `q` a register returns the CLASSICAL `k + 1`. */
int h(int a, int k) { return k + 1; }
