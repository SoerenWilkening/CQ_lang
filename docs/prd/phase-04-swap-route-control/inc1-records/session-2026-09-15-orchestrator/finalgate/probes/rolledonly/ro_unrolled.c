#include "CQ.h"
int slice(void) {
    bool b0[3]; int s = 0;
    b0[0] = cq_theta(b0[0], 0.5);   /* the WRITE loop hand-unrolled: no loop */
    b0[1] = cq_theta(b0[1], 0.5);
    b0[2] = cq_theta(b0[2], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
int main(void) { (void) slice(); return 0; }
