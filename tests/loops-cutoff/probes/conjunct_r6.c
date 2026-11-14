/* tests/loops-cutoff probe, CR rule 6 "In a rolled loop" (owner ruling Q4) across owner ruling Q10's classical exit
 * tests: a carried value read in the loop only by its bijective update, its final value read after the loop, is cleaned
 * per trip; a classical conjunct of the exit test ends the chain at any test. Where a test went on the old rail is
 * cleaned by the next trip (under that test's "went on" flag); where it ended the chain the old rail is the final
 * register (or, made from a seed, garbage undone by its own item). Review finding R1 m1: the clean-up was dropped and
 * the chain freed dirty. Each entry is checked §6 against its own C program (cqcheck user) at K = 4.
 * Regenerate conjunct_r6.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec conjunct_r6.c -o conjunct_r6.O1.ll */
#include "CQ.h"

/* s accumulates a measured bit per trip (a bijective update s + m), x is the quantum exit operand */
unsigned cr_meas(unsigned x0, double th, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0, i;
  for (i = 0; ((m >> i) & 1) && x > 2; i++) { x -= 3; s += cq_measure(x & 1); }
  return s * 256 + cq_measure(x);
}
/* a non-affine carried x */
unsigned cr_shift(unsigned x0, double th, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0, i;
  for (i = 0; ((m >> i) & 1) && x > 2; i++) { x = (x >> 1) ^ 5; s += cq_measure(x & 1); }
  return s * 256 + cq_measure(x);
}
