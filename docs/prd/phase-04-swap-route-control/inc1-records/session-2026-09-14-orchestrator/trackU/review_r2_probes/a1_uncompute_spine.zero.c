/* The whole-DAG LIFO uncompute spine over a NORMALIZED rail: the adjoint must
   pair with its forward and the rail must be freed at a proven |0>. */
#include "CQ.h"
int main(void) { int s = 0; int q = cq_theta(s, 0.5); int r = q + 3; int m = cq_measure(r); int t = 0; t = cq_theta(t, 0.25); return m + cq_measure(t); }
