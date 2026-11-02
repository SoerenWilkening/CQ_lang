#include "CQ.h"
/* cq-un6w (CR rules 9, 18, 20): as clone_store_cycle_error under a quantum condition (mergedCloneStore): one
   arm store on a cycle is two slot results for one cell; stops loudly. */
__attribute__((noinline)) static void w(int *p, int x, int n) {
  for (int i = 0; i < 4; i++)
    if (x & (1 << i)) *p = x + i;
}
int clone_store_cycle_quantum_error(int n) {
  int x = 0; cq_theta(&x, 0.5);
  int c = x * 3;
  w(&c, x, (n + 3) & 15);
  return c ^ (n >> 4);
}
