/* The bd `zujr` CORRECTNESS BOUNDARY, as a program: the owner's cascade followed
   by a NON-DIAGONAL gate on the register the leftovers record. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0[3];
    for (int i = 0; i < 3; ++i) { if (a >= 3) b0[i] = cq_theta(b0[i], 0.5); if (b0[i]) a -= 3; }
    a = cq_theta(a, -0.5);
    return cq_measure(b0[0]) + cq_measure(a);
}
