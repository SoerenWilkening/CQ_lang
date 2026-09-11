#include "CQ.h"
int main(void) {
    int p = cq_theta(0, 0.3);
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (p >= 0){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a = p;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    return cq_measure(b0)+cq_measure(b1)+cq_measure(a)+cq_measure(p);
}
