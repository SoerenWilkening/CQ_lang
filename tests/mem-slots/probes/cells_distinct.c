#include "CQ.h"
/* M3b/M3c (114, CR rules 5, 20): the CCRy on q[m-3] is no alias hit on the flag chain reading q[m-2] (another
   cell, a distinct run-time read) nor on the fresh xor rail stored into q[m-1] after q[m-3] was read: the chain is
   uncomputed after the gate. Main stopped at the alias hit. */
#include <stdbool.h>
int cells_distinct(int n, int m, double t, double u) {
  bool q[n];
  for (int i = 0; i < n; i++) { q[i] = 0; cq_theta(&q[i], t); }
  q[m - 1] ^= q[m - 3];
  int s = 2 * q[m - 1] + q[m - 2];
  if (s == 3) cq_theta(&q[m - 3], u);
  q[m - 1] ^= q[m - 3];
  int r = 0;
  for (int i = 0; i < n; i++) r |= cq_measure(q[i]) << i;
  return r;
}
