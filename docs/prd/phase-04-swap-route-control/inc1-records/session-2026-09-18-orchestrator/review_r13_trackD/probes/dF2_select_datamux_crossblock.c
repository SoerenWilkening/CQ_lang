// The 4.4 tainted-condition DATA SELECT on a CSE'd cross-block compare (bd 9ymx
// already lifted the select's own blanket cross-block decline -- confirm it is
// unmoved by this change).
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  if (q == 5) r = cq_theta(r, 0.9);
  int a = (q == 5) ? 2 : 5;
  return cq_measure(a) + cq_measure(r);
}
