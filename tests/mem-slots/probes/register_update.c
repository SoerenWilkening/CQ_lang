#include "CQ.h"
/* Register updates (CR rules 6, 20; 114): 114's 2-qubit block, `q[m-1] ^= q[m-2]; if (q[m-1]) CRy(q[m-2]);
   q[m-1] ^= q[m-2]`, over a runtime-length _Bool register array in a classically bounded loop. Each xor's rail
   is the cell's new register and the superseded rail (a run-time read of the cell, then the first xor's rail)
   is cleaned by rule 6 right after the store, before the CRy rotates the xor's other operand: t = new ^ q[m-2],
   copied into the old rail, t uncomputed, both freed. Nothing is left for the loop's reverse. Main stopped at
   'a kept exit rail of a deferred rule-14 reverse loop that was rotated'. */
#include <stdbool.h>
int register_update(int n, double t) {
  bool q[n];
  for (int i = 0; i < n; i++) q[i] = (i >= n / 2);
  for (int m = n; m >= 2; m--) {
    q[m - 1] ^= q[m - 2];
    if (q[m - 1]) cq_theta(&q[m - 2], t);
    q[m - 1] ^= q[m - 2];
  }
  int r = 0;
  for (int i = 0; i < n; i++) r |= cq_measure(q[i]) << i;
  return r;
}
