/* (5) 3-phi merge: two peelable data muxes + one arm-defined prep */
#include "CQ.h"
int main(void) {
    int a = 5; int c = 9; int b0 = 0; int b1 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) { a -= 3; c -= 4; }
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a) + cq_measure(c);
}
