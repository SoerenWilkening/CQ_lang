/* slice_z0re_runtime_seed_loop_unrolled.c — the HAND-UNROLLED TWIN of
   slice_z0re_runtime_seed_loop.c (three straight-line copies, k = 0, 1, 2). The twin
   defines the correct circuit; the rolled golden must stay byte-identical to this
   one (`e2e-z0re-runtime-seed-loop-twin-identical`).
   bd test_C_libtooling-z0re — OWNER RULING 2026-09-28, option (a): a RUNTIME
   state-prep seed (PRD §14.11 Q2, bd drbq.14) and an UNTAINTED Ry-stem angle-select
   base are admitted on the DIRECT path, so the hand-inlined twin and the
   spec-classical side door ACCEPT with the same circuit. The runtime value is
   `argc`-derived (the harness runs the slice with no arguments, so argc = 1) — a
   value `clang -O1` cannot fold, never a literal passed through a noinline call
   (bd 46oo: `-O1` const-propagates a literal argument). */
__attribute__((noinline)) int slice(int m, int s) {
    int acc = 0;
    { int q = m + 0; cq_theta(&q, 0.5); int r = s + 0; if (q > 0) { r = s + 0; cq_theta(&r, 0.2); } acc += cq_measure(r); }
    { int q = m + 1; cq_theta(&q, 0.5); int r = s + 1; if (q > 1) { r = s + 1; cq_theta(&r, 0.2); } acc += cq_measure(r); }
    { int q = m + 2; cq_theta(&q, 0.5); int r = s + 2; if (q > 2) { r = s + 2; cq_theta(&r, 0.2); } acc += cq_measure(r); }
    return acc;
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4, argc + 6);
    return 0;
}
