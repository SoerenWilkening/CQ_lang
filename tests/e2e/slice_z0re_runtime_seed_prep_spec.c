/* slice_z0re_runtime_seed_prep_spec.c — the SPEC-CLASSICAL spelling of
   slice_z0re_runtime_seed_prep.c: `t = h(q, m)` through the 2-TU library
   `spec_lift_classical_lib.c` (`h(a, k) = k + 1`, `a` stored to a volatile local).

   Since bd vsfp the dead-argument drop makes the call `h(0, m)` before the
   specializer sees it (the lib's own header says why), so from C this spelling no
   longer goes through bd z0re's side door — it IS the twin, and its golden is pinned
   BYTE-IDENTICAL to slice_z0re_runtime_seed_prep.expected.log
   (`e2e-z0re-runtime-seed-prep-twin-identical`). The side door itself is reachable
   only from hand IR and is pinned by `spec_stateprep_runtime_seed_side_door{,_twin}.ll`.
   On the ORACLE (main 9a230646) BOTH C spellings declined at F1.
   bd test_C_libtooling-z0re — OWNER RULING 2026-09-28, option (a): a RUNTIME
   state-prep seed (PRD §14.11 Q2, bd drbq.14) and an UNTAINTED Ry-stem angle-select
   base are admitted on the DIRECT path, so the hand-inlined twin and the
   spec-classical side door ACCEPT with the same circuit. The runtime value is
   `argc`-derived (the harness runs the slice with no arguments, so argc = 1) — a
   value `clang -O1` cannot fold, never a literal passed through a noinline call
   (bd 46oo: `-O1` const-propagates a literal argument). */
int h(int a, int k);

__attribute__((noinline)) int slice(int m, int n) {
    int q = m; cq_theta(&q, 0.5);
    int t = h(q, m);
    int q2 = n; cq_theta(&q2, 0.3);
    int r = t;
    if (q2 > 3) { r = t; cq_theta(&r, 0.2); }
    return cq_measure(r) + cq_measure(q2);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4, argc + 6);
    return 0;
}
