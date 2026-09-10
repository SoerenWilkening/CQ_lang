/* e02 — the same round-2 window, MEASURE form: `cq_measure(x)` before the
   select, where `x` is only tainted at round 2 so the closure never saw it. */
#include "CQ.h"
static int f(int v) { return v * 3 + 1; }
int main(void) {
  int q = 0; q = cq_theta(q, 0.2);
  int y = 5;
  if (q > 5) y = f(7);
  bool x = (bool)(y & 1);
  bool b = cq_theta(x, 0.5);
  int mx = cq_measure(x);
  int a = b ? 2 : 5;
  return cq_measure(a) + mx + cq_measure(q);
}
