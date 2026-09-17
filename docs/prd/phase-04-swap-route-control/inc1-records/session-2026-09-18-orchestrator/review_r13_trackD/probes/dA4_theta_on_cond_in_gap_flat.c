// CONTROL for dA2/dA3: a CHAINED theta on the condition's own rail in the gap.
// Must decline (the wire-scoped gap scan is exactly this).
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  if (q == 5) r = cq_theta(r, 0.9);
  int t = cq_theta(q, 0.2);           /* relabels q's rail IN PLACE, in the gap */
  if (q == 5) r = cq_theta(r, 0.7);
  return cq_measure(t) + cq_measure(r);
}
