// ATTACK 1 (L1 PREDICATE species): the gap carries a theta whose arg-0 derives from
// a 4.4 select's merge %out -- the value repropagateControlMerges re-seeds in ROUND 2.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int a = (q == 5) ? 2 : 5;
  if (q == 5) r = cq_theta(r, 0.9);
  int w = cq_theta(a, 0.2);
  if (q == 5) r = cq_theta(r, 0.7);
  return cq_measure(w) + cq_measure(r);
}
