#include "CQ.h"
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    int s = 0;
    for (int i = 0; i < 3; ++i) {
        bool b1 = 0;
        if (b0) { b1 = cq_theta(b1, 0.5); }
        if (b1) cq_phi(0.3);
        s += cq_measure(b1);
    }
    return s + cq_measure(b0);
}
