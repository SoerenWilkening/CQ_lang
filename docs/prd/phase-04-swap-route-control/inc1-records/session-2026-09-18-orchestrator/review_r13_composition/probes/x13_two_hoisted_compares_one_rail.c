// COMPOSITION ATTACK 1(c). TWO hoisted compares over ONE hoisted rail, i.e. two
// sequential in-loop regions sharing the rail P2 must discharge exactly once.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int u = cq_theta(0, 0.2);
  int t = q & 3;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
    if (t == 2) u = cq_theta(u, 0.7);
  }
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r) + cq_measure(u);
}
