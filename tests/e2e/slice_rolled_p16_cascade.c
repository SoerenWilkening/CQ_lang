/* slice_rolled_p16_cascade.c — bd test_C_libtooling-01po.19 S6 (quantum control
   on cells of a rolled quantum array; design §5, owner ruling
   owner-ruling-01po19-rolled-design-2026-10-15). docs/CQ_FINDINGS.md F5's p16.

   Each trip reads q[i-1] as the CONDITION REGISTER (a cell read is the rail it
   names: nothing minted, stripped or freed) and rotates q[i] IN PLACE under it
   (`cqrt_ry_i1_controlled`, the target then frozen, R6). The cells' rails are
   minted by the walk at the quantization point; cell 0 is rebound to the rail
   of the first `cq_theta` (owner Q3: its |0> rail is left allocated).

   ANALYTIC CHECK (scratch state-vector propagation of THIS golden, 2026-10-15;
   no simulator in the repo, owner decision 2026-06-10): the stream is exactly
   Ry(.5) q0; CRy(q0 -> q1, .6); CRy(q1 -> q2, .9); CRy(q2 -> q3, 1.2), the
   circuit the source spells. With c(x) = cos(x/2), s(x) = sin(x/2), the
   amplitudes over (q0 q1 q2 q3) are |0000> c(.5) = .968912, |1000> s(.5) c(.6)
   = .236354, |1100> s(.5) s(.6) c(.9) = .065834, |1110> s(.5) s(.6) s(.9)
   c(1.2) = .026247, |1111> s(.5) s(.6) s(.9) s(1.2) = .017957 (P = .938791,
   .055863, .004334, .000689, .000322; sum 1). The trace-only runtime measures
   0, so main returns 0. */
#include <stdbool.h>
int main(void) {
  bool q[4] = {0};
  cq_theta(&q[0], .5);
  for (int i = 1; i < 4; i++)
    if (q[i-1]) cq_theta(&q[i], .3 * (i + 1));
  int r = 0;
  for (int i = 0; i < 4; i++) r += cq_measure(q[i]);
  return r;
}
