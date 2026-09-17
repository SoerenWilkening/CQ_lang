#include "CQ.h"
int main(void) {
    _Bool a = 0;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        if (!a) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a = 1;
    }
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a);
}
