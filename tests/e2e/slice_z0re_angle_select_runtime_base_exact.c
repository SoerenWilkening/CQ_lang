/* slice_z0re_angle_select_runtime_base_exact.c — the Ry-stem angle select on an
   UNTAINTED RUNTIME base with angles whose difference is EXACT in binary64
   (A = .75, B = .25, A − B = .5), so its stream can be compared BYTE FOR BYTE with an
   independently cleared spelling (bd test_C_libtooling-z0re, Rule-13 r1B F-r1B-6).

     int t = m + 1; int r; if (q > 3) { r = t; cq_theta(&r, .75); } else { r = t; cq_theta(&r, .25); }

   `-O1` folds it to ONE `@cq_theta_*(t, select(q > 3, .75, .25))`; z0re lowers it by
   difference: alloc(t); ry(h, .25); flag(q > 3); ry_controlled(f, h, .5); strip;
   free. The witness is slice_z0re_angle_select_runtime_base_exact_inplace.c — the
   same unitary written as an UNCONDITIONAL literal prep followed by an in-place
   controlled-Ry ARM on it (the drbq Inc-1 path, cleared code that predates z0re and
   produces its golden on the frozen ORACLE byte for byte) — pinned byte-identical by
   `e2e-z0re-angle-select-runtime-base-exact-inplace-identical`. The runtime value is
   `argc`-derived (m = argc + 4 = 5, t = 6).

   ⚠ RESPELLED AS A TERNARY by bd test_C_libtooling-fmt3 (2026-09-29), exactly as
   z0re's own retirement trigger in tests/e2e/CMakeLists.txt instructed. With
   `nomerge` on every `cq_theta_*` (CQ.h) the IF/ELSE spelling that stood here,
   `if (q > 3) { r = t; cq_theta(&r, A); } else { r = t; cq_theta(&r, B); }`, no longer folds into
   one call — it survives as an if/else of two runtime-seed preps and declines
   `if/else state prep allocates two rails` (measured, fmt3 round-2 header A/B;
   pinned by `control_inplace_ry_reject_stateprep_nomerge_ifelse_runtime_seed.ll`,
   whose retirement trigger names bd gjn2). The TERNARY below produces the
   select-angle call directly — no merge — so the module, the stream and the
   golden are UNCHANGED byte for byte (measured). Where the text above says
   "`-O1` sinks/folds the two thetas", read "the ternary IS the one call".
*/
__attribute__((noinline)) int slice(int m) {
    int q = m; cq_theta(&q, 0.5);
    int t = m + 1;
    int r = t; cq_theta(&r, (q > 3) ? 0.75 : 0.25);
    return cq_measure(r) + cq_measure(q);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
