/* arg-1, the ANGLE, must be untouched (Rule 3). */
#include <CQ.h>
int f(void) {
  double th;            /* uninitialized ANGLE */
  _Bool b = 0;
  b = cq_theta(b, th);
  return cq_measure(b);
}
