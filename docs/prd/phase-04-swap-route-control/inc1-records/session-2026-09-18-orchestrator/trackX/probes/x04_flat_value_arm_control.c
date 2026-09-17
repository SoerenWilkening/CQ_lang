/* x04_flat_value_arm_control.c — Track X (bd x5fp), session 2026-09-18.
   POSITIVE CONTROL, NO LOOP: the shipped in-arm VALUE chain the §3c prong at
   ArmClassify.cpp:5774 guards. If this accepts and x03 declines, the wall x03
   hits is the LOOP, not the arm class. */
#include "CQ.h"
int main(void) {
    int a = 0;
    int q = cq_theta(9, 0.3);
    int r = cq_theta(7, 0.2);
    if (q >= a) r = r + 3;
    return cq_measure(r) + cq_measure(q);
}
