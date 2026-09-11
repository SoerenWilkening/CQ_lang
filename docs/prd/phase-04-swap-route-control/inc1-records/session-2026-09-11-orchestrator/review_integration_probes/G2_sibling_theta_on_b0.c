#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0; bool t = 0;
    b0 = cq_theta(t, 0.5);
    bool c = cq_theta(t, 0.9);
    if (b0 == 1) a -= 3;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    return cq_measure(b0)+cq_measure(b1)+cq_measure(a)+cq_measure(c);
}
