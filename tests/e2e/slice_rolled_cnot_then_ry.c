/* slice_rolled_cnot_then_ry.c — bd test_C_libtooling-01po.19 S5 (in-place cell
   updates over a rolled quantum array; design §4, owner rulings
   owner-ruling-01po19-rolled-design-2026-10-15 and
   owner-ruling-dm7f51-inplace-qq-2026-10-14). The r2j3.33 analytic pin, ROLLED.

   The CNOT walk `q[i+1] ^= q[i]` over a `bool` array lowers IN PLACE: one
   `cqrt_cnot(q[i], q[i+1])` per trip on the cells' own rails (the window
   array's handles), never an out-of-place `cq_template_xor` rebinding the cell
   beside its live old rail. Out of place, the old q[i+1] rail would keep a
   record of q[i] and dephase the final Ry on q[0]: P(q0=0) = 0.836 (measured on
   the unroll branch) where the program's circuit gives 0.736.

   ANALYTIC CHECK (scratch state-vector propagation of THIS golden, 2026-10-15;
   no simulator in the repo, owner decision 2026-06-10): Ry(.5), Ry(.7), Ry(.9)
   on |000>, CNOT(q0 -> q1), CNOT(q1 -> q2), Ry(.7) on q0 gives over (q0 q1 q2)
       000 .553058  001 .129052  010 .010219  011 .043793
       100 .124456  101 .029041  110 .020884  111 .089498
   so P(q0=0) = 0.736122, the textbook value. The three cell rails are minted
   by the walk at the quantization point (alloc_i1(0) each, Q1 (a)); none is
   freed (R5: a cell holds user data). The trace-only runtime measures 0, so
   main returns 0. */
int main(void) {
  bool q[3] = {0};
  for (int i = 0; i < 3; i++) cq_theta(&q[i], .5 + .2 * i);
  for (int i = 0; i < 2; i++) q[i + 1] ^= q[i];
  cq_theta(&q[0], .7);
  int r = 0;
  for (int i = 0; i < 3; i++) r = 2 * r + cq_measure(q[i]);
  return r;
}
