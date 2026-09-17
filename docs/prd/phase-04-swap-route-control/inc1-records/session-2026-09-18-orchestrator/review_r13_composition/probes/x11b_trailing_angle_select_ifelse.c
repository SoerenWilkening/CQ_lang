// COMPOSITION ATTACK 6b, second spelling. `AngleSelectEmit`'s Ry stem needs an
// if/else over the SAME register with CONSTANT arms; the folded `b ? .9 : .2`
// written inside the call read as a quantum-derived ANGLE and declined (x11).
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  _Bool b = cq_theta(0, 0.4);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
  }
  if (b) q = cq_theta(q, 0.9); else q = cq_theta(q, 0.2);   /* folded angle select */
  return cq_measure(q) + cq_measure(r);
}
