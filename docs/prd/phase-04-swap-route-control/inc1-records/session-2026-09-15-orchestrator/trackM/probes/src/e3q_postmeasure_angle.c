#include "CQ.h"
/* E3 ANGLE: a post-measure read used as a ROTATION ANGLE. Today the angle is tainted
   and `declineTaintedAngle` refuses. Under (b) it is a classical (runtime) angle. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); int r=cq_theta(0,(double)q); return m+cq_measure(r); }
