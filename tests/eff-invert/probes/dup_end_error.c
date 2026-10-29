/* clang -O1 threads the region's condition into the branch after it and duplicates __cq_invert_end into
 * both arms: end's block no longer post-dominates begin's. Not built yet: an internal error (bead cq-asfn). */
#include "CQ.h"
int p_dupend(int x0, double th, int k, double a, double b) {
  int x = x0; cq_theta(&x, th);
  cq_invert_begin();
  if (x == k) cq_phi(b);
  cq_invert_end();
  if (x == k) cq_phi(a);
  return cq_measure(x);
}
