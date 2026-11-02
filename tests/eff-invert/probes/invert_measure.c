/* cq-4593 (BACKEND_ABI 1.13): a measurement inside a cq_invert region flushes the gates recorded before
 * it forward; only the gates after it are reversed at the end. A template made in the region and read by
 * a phase after the measurement is uncomputed inside the region. */
#include "CQ.h"
int p_meas(int x0, int y0, double a, double b, double c, int k, double p) {
  int x = x0; cq_theta(&x, a);
  int y = y0; cq_theta(&y, a);
  cq_invert_begin();
  cq_theta(&x, b);
  int m = cq_measure(x);
  cq_theta(&y, c);
  if (y + m == k) cq_phi(p);
  cq_invert_end();
  return m + cq_measure(y);
}
