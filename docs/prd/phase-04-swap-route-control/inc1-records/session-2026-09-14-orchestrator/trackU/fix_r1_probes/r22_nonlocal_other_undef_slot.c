/* FIX-round probe, the NON-LOCAL member of the same class: the undef seed and
   the surviving undef slot are on DIFFERENT thetas. The seed's own arg-1 is a
   real constant, so NO conjunct local to the theta can see the survivor. This
   measures the residual that the local fix does NOT close. */
#include "CQ.h"
int f(void) {
  _Bool b;      /* undef SEED -- normalized by z9t1 */
  double th;    /* undef ANGLE on an UNRELATED, initialized-seed theta */
  _Bool c = 0;
  b = cq_theta(b, 0.5);
  c = cq_theta(c, th);
  return cq_measure(b) + cq_measure(c);
}
