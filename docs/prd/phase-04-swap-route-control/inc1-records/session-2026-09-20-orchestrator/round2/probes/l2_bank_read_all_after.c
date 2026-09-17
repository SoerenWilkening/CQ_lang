/* l2: every bank cell READ AFTER the loop (the bank escapes wholesale). */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    return cq_measure(a) + cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]);
}
