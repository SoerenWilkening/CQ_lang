#include "CQ.h"
/* Register updates (CR rules 6, 20; 114), out of scope: the old rail of q[1] is still read (a = q[1], measured)
   after `q[1] ^= q[0]` supersedes it, so rule 6 cannot clean it at the store: unimplemented, never a clean-up
   that frees a rail a later read names. */
#include <stdbool.h>
int register_update_live(int n, double t) {
  bool q[n];
  for (int i = 0; i < n; i++) { q[i] = (i >= n / 2); cq_theta(&q[i], t); }
  bool a = q[1];
  q[1] ^= q[0];
  return cq_measure(a) + 2 * cq_measure(q[1]);
}
