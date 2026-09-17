// COMPOSITION ATTACK 6a. The gate's blast-radius scan looked for `left dirty > 0`
// plus a trailing `cqrt_ry_<W>(h, θ)`. Here the trailing non-diagonal gate is a
// `cqrt_ry_<W>_controlled(f, h, θ)` (a bool-controlled in-place Ry), which that
// scan's pattern does not name.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  _Bool b = cq_theta(0, 0.4);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
  }
  if (b) q = cq_theta(q, 0.9);       /* trailing CONTROLLED non-diagonal gate */
  return cq_measure(q) + cq_measure(r) + cq_measure(b);
}
