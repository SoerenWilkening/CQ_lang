/* tests/replay probe (cq-kcn5i): a pure clone called four times with the same quantum argument: three replays. */
#include "CQ.h"
__attribute__((noinline, weak)) int f(int x, int k) { return x * x + k; }
int rp_pure(int a, double th) {
  cq_theta(&a, th);
  int s = 0;
#pragma clang loop unroll(full)
  for (int i = 0; i < 4; ++i)
    s += f(a, 3);
  return cq_measure(s);
}
