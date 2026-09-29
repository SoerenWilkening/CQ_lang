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
   (bd 46oo: `-O1` const-propagates a literal argument). */
__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int t = m + 1;
    int r;
    if (q > 3) r = cq_theta(t, 0.7); else r = cq_theta(t, 0.2);
    return cq_measure(r) + cq_measure(q) + t;
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
