/* rule 5 inside a region (cq-ja5h): an Ry on the register after a template of the region read it, before
 * that template's uncompute: unimplemented, never a dirty free. */
#include "CQ.h"
int p_barrier(int x0, double th, int c, int k, double phi, double t2) {
  int x = x0; cq_theta(&x, th);
  cq_invert_begin();
  int y = x * c;
  if (y == k) cq_phi(phi);
  cq_theta(&x, t2);
  cq_invert_end();
  return cq_measure(x);
}
