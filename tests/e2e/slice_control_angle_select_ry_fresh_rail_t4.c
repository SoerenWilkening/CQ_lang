/* slice_control_angle_select_ry_fresh_rail_t4.c — THE REPORTER'S t4.c, FIRST
   TWO ROTATIONS (bd dm7f.54, CQ_FINDINGS F4). Harness edit: `main` -> `slice`,
   `printf` -> the returned sum, and t4's third rotation (a NESTED ternary,
   `c == 0 ? .1 : (c == 1 ? .2 : .4)`) is cut: the nested angle mux is a
   separate follow-up and still declines `rotation angle`.

   `c == 0 ? 0.3 : 0.7` over `c = q0` folds at -O1 to `select i1 %q0, .7, .3`
   (a bare `_Bool` condition, arms swapped) feeding `cq_theta_i1(false, ·)`: a
   FRESH |0> target. It declined `rotation angle` (literal seed, drbq.13). The
   `nomerge` call site proves no SimplifyCFG sink made it, so it lowers as
   controlled state prep; the condition is a CNOT COPY flag, so no `cqrt_x`
   touches q0 (owner ruling angle-select-xbracket 2026-10-13).

   READ THE GOLDEN:
      1-2    q0's rail + Ry(1.0).
      3      c = zext(q0): the template copy h1 (CNOT into a fresh rail).
      4-5    bf = |0>, cnot(q0, bf): bf = q0 on every basis branch.
      6      q1's FRESH rail (the literal seed), minted |0>.
      7      Ry(.7) on q1 controlled by bf      (q0 = 1, i.e. c != 0)
      8-10   x(bf); Ry(.3) controlled by bf; x(bf)   (q0 = 0, i.e. c == 0)
      11-12  cnot(q0, bf): bf back to 0; free(bf) — a proven-|0> free.
      13-16  c += q1: zext(q1) -> h4, add -> h5, zext un-computed, h4 freed.
      17-19  the three measurements.
   Analytic: q0 = cos(.5)|0> + sin(.5)|1>; q1 = Ry(.3)|0> on q0 = 0 and
   Ry(.7)|0> on q0 = 1, i.e. `c == 0 ? .3 : .7`. Each angle reaches one gate. */
int slice(void) {
    _Bool q0 = 0, q1 = 0;
    int c = 0;
    cq_theta(&q0, 1.0);
    c += q0;
    cq_theta(&q1, c == 0 ? 0.3 : 0.7);
    c += q1;
    return (int) cq_measure(q0) + (int) cq_measure(q1) + cq_measure(c);
}
int main(void) { (void) slice(); return 0; }
