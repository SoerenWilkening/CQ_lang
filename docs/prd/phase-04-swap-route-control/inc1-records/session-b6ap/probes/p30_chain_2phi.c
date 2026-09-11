/* (4) 2-phi merge, BOTH arm incomings DEFINED IN THE ARM — not peelable */
#include "CQ.h"
int main(void) {
    int b0 = cq_theta(0, 0.5);
    int r = b0 + 1;
    int s = 0;
    if (b0 == 1) { r = r * 3 + 1; s = r + 7; }
    return cq_measure(b0) + cq_measure(r) + cq_measure(s);
}
