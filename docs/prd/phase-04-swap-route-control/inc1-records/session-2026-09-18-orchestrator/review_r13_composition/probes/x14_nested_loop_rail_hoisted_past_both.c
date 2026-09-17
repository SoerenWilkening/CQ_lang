// COMPOSITION ATTACK 1(d). The rail is hoisted past BOTH loops of a nest and the
// compare with it; `anchorForConsumer` must walk to the OUTERMOST loop.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 2; i++)
    for (int j = 0; j < 2; j++)
      if (t == 1) r = cq_theta(r, 0.9);
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r);
}
