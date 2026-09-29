/* slice_z0re_angle_select_runtime_base_spec.c — the SPEC-CLASSICAL spelling of
   slice_z0re_angle_select_runtime_base.c (`t = h(q, m)`, 2-TU with
   `spec_lift_classical_lib.c`). As for the prep pair, the vsfp drop makes it the
   twin from C, and its golden is pinned BYTE-IDENTICAL
   (`e2e-z0re-angle-select-runtime-base-twin-identical`); the hand-IR side door is
   `spec_angle_select_runtime_base_side_door{,_twin}.ll`. On the ORACLE both C
   spellings declined `rotation angle under quantum control`.
   bd test_C_libtooling-z0re — OWNER RULING 2026-09-28, option (a): a RUNTIME
   state-prep seed (PRD §14.11 Q2, bd drbq.14) and an UNTAINTED Ry-stem angle-select
   base are admitted on the DIRECT path, so the hand-inlined twin and the
   spec-classical side door ACCEPT with the same circuit. The runtime value is
   `argc`-derived (the harness runs the slice with no arguments, so argc = 1) — a
   value `clang -O1` cannot fold, never a literal passed through a noinline call
   (bd 46oo: `-O1` const-propagates a literal argument). */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int t = h(q, m);
    int r;
    if (q > 3) r = cq_theta(t, 0.7); else r = cq_theta(t, 0.2);
    return cq_measure(r) + cq_measure(q) + t;
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
