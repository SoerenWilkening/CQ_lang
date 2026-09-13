/* r33 — item 4/6: a CLASSICAL cq_measure inside a PHASE arm, result UNUSED.
   RegionFlatten erases the arm block; if no fence claims the stray call its
   taint.MeasureCalls pointer dangles into lowerMeasures (ArmClassify.cpp:175-187). */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int c = 9;
    if (q == 3) { cq_phi(0.3); (void)cq_measure(c); }
    return cq_measure(q);
}
