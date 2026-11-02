#include "CQ.h"
/* cq-un6w (CR rules 18, 20; gate 2a slots-h1 q1): a clone's store into a caller cell on a cycle (a classical
   loop) under a classical condition. The cq-vxgm guarded copy-out (copy old, copy v into f per execution)
   would give old ^ v1 ^ v2 after two executions: stops loudly. */
__attribute__((noinline)) static void w(int *p, int x, int n) {
  for (int i = 0; i < 4; i++)
    if ((n >> i) & 1) *p = x + i;
}
int clone_store_cycle_error(int n) {
  int x = 0; cq_theta(&x, 0.5);
  int c = x * 3;
  w(&c, x, (n + 3) & 15);
  return c ^ (n >> 4);
}
