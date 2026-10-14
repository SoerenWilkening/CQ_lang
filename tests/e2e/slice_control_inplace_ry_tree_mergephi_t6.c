/* slice_control_inplace_ry_tree_mergephi_t6.c — THE REPORTER'S t6.c, the 3-qubit
   Dicke-style cascade (bd dm7f.53).

   `c` counts the ones so far; each later qubit is rotated by an angle chosen
   by `c`. -O1 turns `c == 1` / `c == 2` over two `_Bool`s into `xor i1` /
   `and i1` whose second leaf is region 1's MERGE phi (q1 after its controlled
   Ry). Before dm7f.53 the in-place Ry consumer refused a merge-phi leaf
   (`control flow`, line 11), and the third region's leaf is CROSS-BLOCK with
   region 2's Ry on q2 in the gap. Harness edit only: `main` -> `slice`,
   `printf` -> the returned sum.

   READ THE GOLDEN:
      1-2   q0 Ry(1.0)                     3-5  q1 Ry(.3), then Ry(.4) under q0
      6-7   q2 Ry(.1)
      8-14  `if (c == 1)`: |0> ancilla, CNOT q0, CNOT q1 (= q0 ^ q1), Ry(.1) on
            q2 under it, CNOT q1, CNOT q0 (back to |0> on every branch), free.
     15-19  `if (c == 2)`: Toffoli(q0, q1) into a |0> ancilla, Ry(.3) on q2
            under it, Toffoli again, free.
     20-32  `c += q2` and the counter's measurement: zext/add templates and
            their `_unc` strips, each rail freed at a proven |0> (stage 2b:
            6 cqrt_free sites, 6 verified, 0 violations).
     33-36  the four measurements.
   q1 appears ONLY as a control after line 5 (read-only); no `cqrt_x` anywhere.
   Analytic: q2 = Ry(.1 + .1·[q0+q1 == 1] + .3·[q0+q1 == 2])|0>. */
int slice(void) {
    _Bool q0 = 0, q1 = 0, q2 = 0;
    int c = 0;
    cq_theta(&q0, 1.0);
    c += q0;
    cq_theta(&q1, 0.3);
    if (c == 1) cq_theta(&q1, 0.4);
    c += q1;
    cq_theta(&q2, 0.1);
    if (c == 1) cq_theta(&q2, 0.1);
    if (c == 2) cq_theta(&q2, 0.3);
    c += q2;
    return (int) cq_measure(q0) + (int) cq_measure(q1) + (int) cq_measure(q2) +
           cq_measure(c);
}
int main(void) { (void) slice(); return 0; }
