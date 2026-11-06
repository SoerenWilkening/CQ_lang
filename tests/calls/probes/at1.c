/* tests/calls probe, cq-haf1p (rule 24): oversize __atomic_store and __atomic_load are ordinary accesses. */
#include "CQ.h"
/* an oversize atomic is the libcall __atomic_load / __atomic_store */
struct B { long a, b, c; };
struct B g;
int at1(int x, double th) {
  cq_theta(&x, th);
  struct B v = { x, 1, 2 };
  __atomic_store(&g, &v, __ATOMIC_SEQ_CST);
  struct B r;
  __atomic_load(&g, &r, __ATOMIC_SEQ_CST);
  return cq_measure((int)r.a + 1);
}
