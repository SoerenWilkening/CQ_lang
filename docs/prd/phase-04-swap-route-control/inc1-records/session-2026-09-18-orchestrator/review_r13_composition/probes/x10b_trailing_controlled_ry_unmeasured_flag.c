// COMPOSITION ATTACK 6a, second spelling. x10 died at `rotation arm shares the
// condition flag` because the `_Bool` was also measured. Here it is not.
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
  return cq_measure(q) + cq_measure(r);
}
