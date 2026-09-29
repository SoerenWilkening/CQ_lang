/* slice_z0re_angle_select_runtime_base.c — the Ry-stem ANGLE SELECT on an
   UNTAINTED RUNTIME base (the d88e probe a01T).

     int t = m + 1; int r; if (q > 3) r = cq_theta(t, .7); else r = cq_theta(t, .2);

   `-O1` sinks the two thetas into ONE `cq_theta(t, select(q > 3, .7, .2))`.
   Expected stream (by difference on a FRESH rail): alloc(t); ry(h, .2) — the
   else-arm angle, UNCONDITIONAL; the flag from `q > 3`; ry_controlled(f, h,
   fl(.7 - .2)); the flag stripped and freed. On f=1 the rail sees Ry(.2)·Ry(.5) =
   Ry(.7), on f=0 Ry(.2): the source's if/else on ONE rail prepared at |t⟩ on both
   branches. The trailing `+ t` reads the classical base AFTER the gate — legal, it is
   not a record of the rotated rail.
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
__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int t = m + 1;
    int r = cq_theta(t, (q > 3) ? 0.7 : 0.2);
    return cq_measure(r) + cq_measure(q) + t;
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
