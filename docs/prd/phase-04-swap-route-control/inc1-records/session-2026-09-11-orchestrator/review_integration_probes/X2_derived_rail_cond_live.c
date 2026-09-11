#include "CQ.h"
int main(void) {
    int q = cq_theta(0, 0.3);
    int s = q + 7;
    bool b0 = cq_theta((bool)(s & 1), 0.5);
    int a = 5; bool b1 = 0;
    if (b0 == 1) a -= 3;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
