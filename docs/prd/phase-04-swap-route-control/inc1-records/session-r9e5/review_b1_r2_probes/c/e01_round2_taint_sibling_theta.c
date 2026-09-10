/* e01 — ROUND-2 TAINT GROWTH under a rail select. `%y` is a 6.5 classical-call
   arm `%out`: CLASSICAL at round 1 (when the select is classified) and TAINTED
   at round 2 (when `lowerRotations` decides chained-vs-source). Two SIBLING
   thetas on `x` then ride ONE rail, and the select's control reads the LATER
   one — the F-1b-1 class, reached through the round-2 window. */
#include "CQ.h"
static int f(int v) { return v * 3 + 1; }
int main(void) {
  int q = 0; q = cq_theta(q, 0.2);
  int y = 5;
  if (q > 5) y = f(7);
  bool x = (bool)(y & 1);
  bool b  = cq_theta(x, 0.5);
  bool b3 = cq_theta(x, 0.9);
  int a = b ? 2 : 5;
  return cq_measure(a) + cq_measure(b3) + cq_measure(q);
}
