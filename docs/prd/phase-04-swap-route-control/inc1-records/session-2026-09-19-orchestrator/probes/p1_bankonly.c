#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) { if (a >= 3) { b0[i] = cq_theta(b0[i], 0.5); } }
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + a;
}
