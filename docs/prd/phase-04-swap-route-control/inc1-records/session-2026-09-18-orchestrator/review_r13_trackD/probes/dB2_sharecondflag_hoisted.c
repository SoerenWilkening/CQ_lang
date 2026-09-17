// ATTACK 4: the hoisted compare is ALSO READ AS DATA -> ShareCondFlag.
// The !R.ShareCondFlag conjunct must keep this on the unconditional decline.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int s = 0;
  for (int i = 0; i < 2; i++) {
    int c = (q == 5);
    if (c) r = cq_theta(r, 0.9);
    s += cq_measure(c);
  }
  return s + cq_measure(r);
}
