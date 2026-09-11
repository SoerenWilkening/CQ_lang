#include "CQ.h"
int main(void) {
    int a = 5; int c = 11; bool b0 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) { cq_phi(0.7); a -= 3; c -= 4; }
    return cq_measure(b0) + cq_measure(a) + cq_measure(c);
}
