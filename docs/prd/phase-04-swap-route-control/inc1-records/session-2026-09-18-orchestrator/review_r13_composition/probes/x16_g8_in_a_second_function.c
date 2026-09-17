// COMPOSITION ATTACK — the bd `1yeu` axis nobody attacks: the g8 BACKSTOP is
// module-scoped and its ledger is a function-local static, but every corpus in
// the tree is ONE FUNCTION PER MODULE. Here the g8 witness lives in a SECOND,
// non-inlined function while `main` is clean. Does the backstop still fire, and
// does the diagnostic name the right function?
#include <CQ.h>
__attribute__((noinline)) static int leaky(int seed) {
  int y = cq_theta(seed, 0.5);
  int s = 0;
  for (int k = 1; k <= 4; ++k) {
    int d = (y >> k);
    s += cq_measure(d & 1);
    if (k < 3) { int e = d + 7; s += cq_measure(e & 2); }
  }
  y = cq_theta(y, 0.9);
  return s + cq_measure(y);
}
int main(void) {
  int q = cq_theta(0, 0.25);
  return leaky(0) + cq_measure(q);
}
