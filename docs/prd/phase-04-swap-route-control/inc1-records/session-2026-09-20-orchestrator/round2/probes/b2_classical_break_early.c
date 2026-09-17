/* b2: carried handle + CLASSICAL break BEFORE the region arm. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0[4];
    for (int i = 0; i < 4; ++i) {
        if (i == 2) break;
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    return cq_measure(a);
}
