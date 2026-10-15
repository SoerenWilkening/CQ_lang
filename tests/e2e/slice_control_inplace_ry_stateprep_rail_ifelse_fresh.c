/* slice_control_inplace_ry_stateprep_rail_ifelse_fresh.c — the FRESH-TARGET if/else
   (bd dm7f.54 item B; delegated ruling ruling-dm7f54-literal-base-and-ifelse-prep-
   2026-10-15, Q2). Both arms prepare the SAME literal seed (`bool t = 0`), which
   declined `if/else state prep allocates two rails` (archived Q4). It now lowers
   as ONE rail, byte-identical to the ternary twin
   `slice_control_angle_select_ry_fresh_rail_ternary.c`
   (`e2e-stateprep-ifelse-fresh-twin-identical`).

   READ THE GOLDEN:
      1-2    q's rail + Ry(1.0).
      3-4    bf = |0>, cnot(q, bf).
      5      t's FRESH rail (the shared seed 0).
      6      Ry(.3) on t controlled by bf          (q = 1)
      7-9    x(bf); Ry(.7) controlled by bf; x(bf)  (q = 0)
      10-11  cnot(q, bf); free(bf).
      12-13  the measurements.
   Analytic: t = Ry(.3)|0> on q = 1, Ry(.7)|0> on q = 0. Harness edit only. */
int slice(void) {
    _Bool q = 0, t = 0;
    cq_theta(&q, 1.0);
    if (q) cq_theta(&t, 0.3); else cq_theta(&t, 0.7);
    return (int) cq_measure(q) + (int) cq_measure(t);
}
int main(void) { (void) slice(); return 0; }
