#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0 = 0;
    bool b1 = 0;
    bool b2 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); b2 = cq_theta(b2, 0.7); }
    return cq_measure(b0)+cq_measure(b1)+cq_measure(b2)+cq_measure(a);
}
