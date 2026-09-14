/* SOURCE-only: a chained theta on a normalized rail. */
#include <CQ.h>
int f(void) {
  _Bool b;
  b = cq_theta(b, 0.5);
  b = cq_theta(b, 0.25);
  return cq_measure(b);
}
