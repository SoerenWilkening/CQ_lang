/* slice_control_angle_select_ry_rail_p12.c — Ry ANGLE SELECT on a bare `_Bool`
   condition, prepped target (bd dm7f.54, CQ_FINDINGS F4 probe p12; the l4x4.a
   shape, closed without being built). It declined `bare i1 register condition`.
   Harness edit only. Its if/else twin is
   `slice_control_inplace_ry_rail_ifelse_p12_twin.c`; the two goldens are
   byte-identical (`e2e-angle-select-ry-rail-twin-identical`).

   READ THE GOLDEN:
      1-2    a's rail + Ry(1.0).
      3-4    t's rail + Ry(.4) (the prepped target).
      5-6    bf = |0>, cnot(a, bf).
      7      Ry(.7) on t controlled by bf          (a = 1)
      8-10   x(bf); Ry(.3) controlled by bf; x(bf)  (a = 0)
      11-12  cnot(a, bf); free(bf) — bf = a ⊕ a = 0, proven |0>.
      13-14  the measurements; a and t are never freed (Rule 5).
   Analytic: t = Ry(.7)Ry(.4)|0> = Ry(1.1)|0> on a = 1, Ry(.3)Ry(.4)|0> =
   Ry(.7)|0> on a = 0; a is read in control slots only. */
int slice(void) {
    _Bool a = 0, t = 0;
    cq_theta(&a, 1.0);
    cq_theta(&t, 0.4);
    cq_theta(&t, a ? 0.7 : 0.3);
    return (int) cq_measure(a) + (int) cq_measure(t);
}
int main(void) { (void) slice(); return 0; }
