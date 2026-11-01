#include "CQ.h"
/* cq-muau: a classical integer store wider than the cells at a constant offset (-O1 initialises q[4] = {1, 0, 1, 0}
   with one i32 store) is split into one seed per cell; the cells keep their width, so the loop may store at run-time
   offsets (120 register_grid). cqcheck user: PASS (300 samples). */
int split_cells(unsigned x0, double t, int n, int k) {
  unsigned char q[4] = {1, 0, 1, 0};
  unsigned x = x0;
  cq_theta(&x, t);
  for (int i = 0; i < n && i < 4; i++)
    q[i] = (unsigned char)(x + i);
  return cq_measure(q[k & 3] + q[(k + 1) & 3]);
}
