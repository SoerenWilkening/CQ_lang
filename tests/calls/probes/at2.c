/* tests/calls probe. */
#include "CQ.h"
/* rule 24: __atomic_exchange and __atomic_compare_exchange oversize, quantum content */
struct B { long a, b, c; };
struct B g;
int at2(int x, int k, double th) {
  cq_theta(&x, th);
  struct B v = {x, 1, 2}, o = {k, 3, 4}, r;
  __atomic_store(&g, &o, __ATOMIC_SEQ_CST);
  __atomic_exchange(&g, &v, &r, __ATOMIC_SEQ_CST);
  struct B e = {x, 1, 2}, d = {7, 8, 9};
  int ok = __atomic_compare_exchange(&g, &e, &d, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
  return cq_measure((int)r.a + (int)g.a + ok);
}
