// COMPOSITION ATTACK 6b. The trailing non-diagonal gate is a FOLDED ANGLE SELECT
// (`AngleSelectEmit`, Ry stem by difference): an unconditional `ry(h, B)` plus one
// `ry_controlled(f, h, A-B)`. Neither spelling is `cqrt_ry_<W>(h, θ)` alone.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  _Bool b = cq_theta(0, 0.4);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
  }
  q = cq_theta(q, b ? 0.9 : 0.2);    /* folded angle select on the parent */
  return cq_measure(q) + cq_measure(r) + cq_measure(b);
}
