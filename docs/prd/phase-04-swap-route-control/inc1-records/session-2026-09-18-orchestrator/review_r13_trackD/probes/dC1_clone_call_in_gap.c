// ATTACK 2 (vocabulary): the gap scan's evidence is a `cq_theta_*` CALL ONLY.
// A Phase-6 clone-on-taint CALL that rotates its handle IN PLACE is invisible to
// BOTH the old wire-blind P5 and the new wire-scoped scan (both match by name).
#include <CQ.h>
__attribute__((noinline)) static int bump(int x) { return cq_theta(x, 0.2); }
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  if (q == 5) r = cq_theta(r, 0.9);   /* region 1 */
  int z = bump(q);                    /* in the gap: relabels q's rail inside a callee */
  if (q == 5) r = cq_theta(r, 0.7);   /* region 2, CSE'd cross-block compare */
  return cq_measure(z) + cq_measure(r);
}
