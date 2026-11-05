/* tests/eff-invert probes (cq-eive): seeds a cq_invert region prepares (rule 17 with rules 2, 7, 20).
 * p_seedin: a register made from a classical value computed inside the region, rotated on every trip of a
 *   classical do-while loop (a quantum phi at the loop header whose entry incoming is made in the region).
 * p_seedtrip: a register prepared on every trip and kept (one seed per trip, reversed per trip).
 * p_seedarm: a register prepared on one classical arm only. */
#include "CQ.h"
int p_seedin(int x0, double tx, int c, const double *th, int n) {
  int x = x0;
  cq_theta(&x, tx);
  cq_invert_begin();
  int r = c * 3 + 1;
  int i = 0;
  do
    cq_theta(&r, th[i]);
  while (++i < n);
  cq_invert_end();
  return cq_measure(r) + cq_measure(x);
}
int p_seedtrip(int x0, double tx, const double *th, int n, int k) {
  int x = x0;
  cq_theta(&x, tx);
  cq_invert_begin();
  for (int i = 0; i < n; i++) {
    int t = i + k;
    cq_theta(&t, th[i]);
  }
  cq_invert_end();
  return cq_measure(x);
}
int p_seedarm(int x0, double tx, int c, double a, double b) {
  int x = x0;
  cq_theta(&x, tx);
  cq_invert_begin();
  if (c > 0) {
    int t = c;
    cq_theta(&t, a);
  }
  cq_theta(&x, b);
  cq_invert_end();
  return cq_measure(x);
}
