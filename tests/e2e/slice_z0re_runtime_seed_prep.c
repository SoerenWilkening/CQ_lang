/* slice_z0re_runtime_seed_prep.c — a controlled STATE PREP whose seed is a RUNTIME
   value (the d88e probe l12T, the hand-inlined twin of the side door l12C).

     int t = m + 1; int r = t; if (q2 > 3) { r = t; cq_theta(&r, .2); }

   Expected stream (12 lines, ONE `cqrt_free`): `m`'s register is prepared and,
   being DEAD in `slice` (`q` is never read), reverse-played by the spine
   (`ry(h0, -.5)`) and KEPT: its argc-derived birth value is 5, so Ry-dagger
   restores |5>, not |0> (bd 5c5b, libcqops vmz9 — this golden used to free it,
   a dirty reset that stage 2b's (A2) clause certified and the backend convicts);
   `q2`'s register is prepared; the flag is minted from `q2 > 3`; a FRESH rail is
   allocated with the RUNTIME seed `t = m + 1` and rotated by `.2` UNDER the flag;
   the flag is stripped and freed (the one `cqrt_free`); `r` and `q2` are
   measured. `q2` is never rotated by the arm, and the prepped rail is left
   allocated (Rule 6: Ry(θ)|t⟩ is not |0⟩).
   bd test_C_libtooling-z0re — OWNER RULING 2026-09-28, option (a): a RUNTIME
   state-prep seed (PRD §14.11 Q2, bd drbq.14) and an UNTAINTED Ry-stem angle-select
   base are admitted on the DIRECT path, so the hand-inlined twin and the
   spec-classical side door ACCEPT with the same circuit. The runtime value is
   `argc`-derived (the harness runs the slice with no arguments, so argc = 1) — a
   value `clang -O1` cannot fold, never a literal passed through a noinline call
   (bd 46oo: `-O1` const-propagates a literal argument). */
__attribute__((noinline)) int slice(int m, int n) {
    int q = m; cq_theta(&q, 0.5);
    (void) q;
    int t = m + 1;
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
