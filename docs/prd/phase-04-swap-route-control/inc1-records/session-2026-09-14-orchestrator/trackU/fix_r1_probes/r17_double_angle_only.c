/* CONTROL for r14/r15: a DEFINED seed and an undef ANGLE at f64. If both
   binaries already accept this and emit `cqrt_ry_f64(h, double undef)`, then
   the lone-undef-angle accept is PRE-EXISTING and z9t1 only widens its
   population by demolishing the one guard that caught the f64 composition. */
#include "CQ.h"
int main(void) {
    double t;
    double r = cq_theta(0.0, t);
    return (int)cq_measure(r);
}
