/* rule 17 defines no adjoint of a region whose quantum value is read after it: an internal error. */
#include "CQ.h"
int p_out(int x0, double th, int c) {
  int x = x0; cq_theta(&x, th);
  cq_invert_begin();
  int y = x * c;
  cq_invert_end();
  return cq_measure(y);
}
