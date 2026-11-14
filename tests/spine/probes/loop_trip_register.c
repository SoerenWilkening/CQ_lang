/* tests/spine probe (cq-8plep, CR rule 19 mint sites, rule 14 K trips): a register minted in one trip of a K-loop is
 * bound to no original value at the return (the next trip and the exit rebind the loop's values); its mint site is
 * the cq_theta that rotated it. Two shapes: a rotation behind a classical branch beside a cq_measure, and a fresh
 * register per trip. ph_theta's §6 fails on a leak of the per-trip copies (cq-bxikv, loops-cutoff), not on this site. */
#include "CQ.h"
unsigned ph_theta(unsigned x0, double th, unsigned k, int c, unsigned y0) {
  unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
  unsigned m = 0;
  while (x > k) {
    x >>= 1;
    if (c & 1) m += cq_measure(y & 3);
    if (c & 2) cq_theta(&y, 0.25);
  }
  return m * 16 + cq_measure(y);
}
unsigned f_fresh(unsigned x0, double th, unsigned k, unsigned y0) {
  unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
  unsigned m = 0;
  while (x > k) { x >>= 1; unsigned t = (y + x) & 3; cq_theta(&t, 0.25); m ^= t; }
  return m;
}
