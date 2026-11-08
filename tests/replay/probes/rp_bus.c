/* tests/replay probe (cq-kcn5i): a _ctl clone that loads and stores through the bus, called under quantum predicates
 * that repeat: replays apply its cell writes, its tape slots and kept rails. */
#include "CQ.h"
__attribute__((noinline)) static void put(char *p, int i, char v) { p[i] = (char)(p[i + 1] + v); }
int rp_bus(int a, double th) {
  char buf[8] = {1, 2, 3, 4, 5, 6, 7, 8};
  cq_theta(&a, th);
#pragma clang loop unroll(full)
  for (int i = 0; i < 4; ++i)
    if (a > 1)
      put(buf, 2, 5);
  return cq_measure(buf[2]) + cq_measure(buf[1]);
}
