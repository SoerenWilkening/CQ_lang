/* clang -O1 threaded the shared condition and duplicated __cq_invert_begin into both arms of the branch
 * before it (the CQ.h before CQ_spec b137e75). Since b137e75
 * __cq_invert_begin/end are noduplicate (CR rule 17, cq-asfn): the marker stays one call in the block every
 * path reaches, and the region is lowered in place. */
#include "CQ.h"
int p_dup(int x0, double th, int k, double a, double b) {
  int x = x0; cq_theta(&x, th);
  if (x == k) cq_phi(a);
  cq_invert_begin();
  if (x == k) cq_phi(b);
  cq_invert_end();
  return cq_measure(x);
}
