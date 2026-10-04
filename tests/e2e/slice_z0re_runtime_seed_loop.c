/* slice_z0re_runtime_seed_loop.c — a RUNTIME state-prep seed inside a
   classically-bounded loop, ROLLED (the bd wx8g iteration-local rail), with a seed
   the loop RE-COMPUTES every trip (`s + k`). Its hand-unrolled twin is
   slice_z0re_runtime_seed_loop_unrolled.c and the two goldens are pinned
   BYTE-IDENTICAL (`e2e-z0re-runtime-seed-loop-twin-identical`): each activation
   allocates a fresh rail from THAT activation's seed, exactly as each unrolled copy
   does from its own.
   bd test_C_libtooling-z0re — OWNER RULING 2026-09-28, option (a): a RUNTIME
   state-prep seed (PRD §14.11 Q2, bd drbq.14) and an UNTAINTED Ry-stem angle-select
   base are admitted on the DIRECT path, so the hand-inlined twin and the
   spec-classical side door ACCEPT with the same circuit. The runtime value is
   `argc`-derived (the harness runs the slice with no arguments, so argc = 1) — a
   value `clang -O1` cannot fold, never a literal passed through a noinline call
   (bd 46oo: `-O1` const-propagates a literal argument). */
__attribute__((noinline)) int slice(int m, int s) {
    int acc = 0;
    for (int k = 0; k < 3; k++) {
        int q = m + k; cq_theta(&q, 0.5);
        int r = s + k;
        if (q > k) { r = s + k; cq_theta(&r, 0.2); }
        acc += cq_measure(r);
    }
    return acc;
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4, argc + 6);
    return 0;
}
