// ATTACK 1/2: the compare's SSA NAME is loop-invariant (so LICM hoists it) while
// the RAIL it names is RELABELLED IN PLACE every trip by a chained theta in the body.
// The source evaluates `q == 5` ONCE, on the ORIGINAL q. The emitted stream mints
// PER TRIP, on the relabelled rail. Two different circuits.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = 0;
  for (int i = 0; i < 2; i++) {
    if (q == 5) r = cq_theta(r, 0.9);
    t = cq_theta(q, 0.1);          /* IN-PLACE Ry on q's rail, AFTER the region */
  }
  return cq_measure(r) + cq_measure(t);
}
