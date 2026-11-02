/* clang -O1 threads the shared condition and duplicates __cq_invert_begin into both arms of the branch
 * before it: begin's block no longer dominates end's. Not built yet: an internal error (bead cq-asfn). */
#include "CQ.h"
int p_dup(int x0, double th, int k, double a, double b) {
  int x = x0; cq_theta(&x, th);
  if (x == k) cq_phi(a);
  cq_invert_begin();
  if (x == k) cq_phi(b);
  cq_invert_end();
  return cq_measure(x);
}
