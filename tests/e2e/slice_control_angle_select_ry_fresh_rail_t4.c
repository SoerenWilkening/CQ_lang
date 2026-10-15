/* slice_control_angle_select_ry_fresh_rail_t4.c — THE REPORTER'S t4.c, WHOLE
   (bd dm7f.54, CQ_FINDINGS F4). Harness edit only: `main` -> `slice`, `printf`
   -> the returned sum.

   Rotation 2, `c == 0 ? 0.3 : 0.7` over `c = q0`, folds at -O1 to
   `select i1 %q0, .7, .3` on a FRESH `q1` (literal seed on a `nomerge` call):
   controlled state prep on the CNOT copy flag of q0. Rotation 3,
   `c == 0 ? 0.1 : (c == 1 ? 0.2 : 0.4)` with `c = q0 + q1`, is a NESTED angle mux
   (`-O1` spells `c == 1` as `q0 ^ q1` under `c != 0`): one flag per member, a
   path-predicate ancilla per inner leaf, each angle in ONE controlled gate.

   READ THE GOLDEN:
      1-2    q0's rail + Ry(1.0).
      3      c = zext(q0) (template copy h1).
      4-12   q1 = Ry(.7)|0> if q0 else Ry(.3)|0>: bf copy of q0, X-bracket, un-copy.
      13-14  c += q1: zext(q1) -> h4, add -> h5 (= q0 + q1).
      15     f = (h5 == 0)
      16-18  fresh q2; Ry(.1) controlled by f; x(f)  (now f = c != 0)
      19-21  g = q0 ⊕ q1 by two cnots into a fresh ancilla
      22-25  p = f ∧ g; Ry(.2) controlled by p (c == 1); undo p
      26-30  x(g); p = f ∧ ¬g; Ry(.4) controlled by p (c == 2); undo p; x(g)
      31-34  free(p); un-copy g; free(g)
      35-37  x(f); strip f (icmp _unc); free(f)
      38-41  c += q2: zext, add, zext un-computed, freed.
      42-45  the four measurements.
   Analytic: q2 = Ry(.1)|0> on c = 0, Ry(.2)|0> on c = 1, Ry(.4)|0> on c = 2;
   every ancilla (bf, p, g, f) returns to |0> before its free. */
int slice(void) {
    _Bool q0 = 0, q1 = 0, q2 = 0;
    int c = 0;
    cq_theta(&q0, 1.0);
    c += q0;
    cq_theta(&q1, c == 0 ? 0.3 : 0.7);
    c += q1;
    cq_theta(&q2, c == 0 ? 0.1 : (c == 1 ? 0.2 : 0.4));
    c += q2;
    return (int) cq_measure(q0) + (int) cq_measure(q1) + (int) cq_measure(q2)
           + cq_measure(c);
}
int main(void) { (void) slice(); return 0; }
