/* Track L composition: an uninitialized bool ARRAY feeding thetas. */
#include <CQ.h>
int f(int c) {
  _Bool b[2];
  b[0] = cq_theta(b[0], 0.5);
  b[1] = cq_theta(b[1], 0.25);
  return cq_measure(b[0]) + cq_measure(b[1]) + c;
}
