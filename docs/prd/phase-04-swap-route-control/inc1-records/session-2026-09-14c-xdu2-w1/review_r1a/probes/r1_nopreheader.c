#include <stdbool.h>
/* ONE bank. Its write loop's only outside predecessor is ANOTHER loop's latch,
   which has two successors -> Loop::getLoopPreheader() == nullptr. The CARVE
   says Bank (it asks only getExitingBlock/getLoopLatch); planBank's B1/B3
   `!Plan.L->getLoopPreheader()` refuses. Bank AND NOT promoted. */
int slice(int n) {
  int a = 5, t = 0; bool c[3] = {0};
  for (int k = 0; k < n; ++k) t += k;
  for (int i = 0; i < 3; ++i) { if (a >= 3) c[i] = cq_theta(c[i], .5); if (c[i]) a -= 3; }
  int s = cq_measure(a) + t; for (int i = 0; i < 3; ++i) s += cq_measure(c[i]); return s;
}
int main(void){ return slice(4); }
