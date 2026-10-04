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
   (bd 46oo: `-O1` const-propagates a literal argument).

   ⚠ RESPELLED AS A TERNARY by bd test_C_libtooling-fmt3 (2026-09-29), exactly as
   z0re's own retirement trigger in tests/e2e/CMakeLists.txt instructed. With
   `nomerge` on every `cq_theta_*` (CQ.h) the IF/ELSE spelling that stood here,
   `if (q > 3) r = cq_theta(t, A); else r = cq_theta(t, B);`, no longer folds into
   one call — it survives as an if/else of two runtime-seed preps and declines
   `if/else state prep allocates two rails` (measured, fmt3 round-2 header A/B;
   pinned by `control_inplace_ry_reject_stateprep_nomerge_ifelse_runtime_seed.ll`,
   whose retirement trigger names bd gjn2). The TERNARY below produces the
   select-angle call directly — no merge — so the module, the stream and the
   golden are UNCHANGED byte for byte (measured). Where the text above says
   "`-O1` sinks/folds the two thetas", read "the ternary IS the one call".
*/
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = m; cq_theta(&q, 0.5);
    int t = h(q, m);
    int r = t; cq_theta(&r, (q > 3) ? 0.7 : 0.2);
    return cq_measure(r) + cq_measure(q) + t;
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
