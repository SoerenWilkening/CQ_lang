/* w_a — bd wx8g's LITERAL customer: loop-CARRIED rotated register `r`,
   loop-INVARIANT bare-_Bool condition `b`, in-place controlled-Ry arm. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(7, 0.25);
    for (int k = 0; k < CQ_K; ++k) { if (b) r = cq_theta(r, 0.2); }
    return cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
