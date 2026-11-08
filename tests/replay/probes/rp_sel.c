/* tests/replay probe (cq-kcn5i): a clone whose result is a select, called four times with the same quantum argument. */
#include "CQ.h"
__attribute__((noinline, weak)) int pick(int x, int k) { return x > k ? x + 1 : 2 * x; }
int rp_sel(int a, double th) {
  cq_theta(&a, th);
  int s = 0;
#pragma clang loop unroll(full)
  for (int i = 0; i < 4; ++i)
    s += pick(a, 3);
  return cq_measure(s);
}
