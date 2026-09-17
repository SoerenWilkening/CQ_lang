// ATTACK (bd yiid / r903 direction): the condition register is MEASURED inside the
// gap between the CSE'd compare (entry) and region 2's branch. The source compare is
// a snapshot of the PRE-collapse register; the emitted mint reads the POST-collapse one.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  if (q == 5) r = cq_theta(r, 0.9);   /* region 1 -- Pred = entry, compare in entry */
  int m = cq_measure(q);              /* COLLAPSE, squarely in region 2's gap */
  if (q == 5) r = cq_theta(r, 0.7);   /* region 2 -- Pred = region 1's merge */
  return m + cq_measure(r);
}
