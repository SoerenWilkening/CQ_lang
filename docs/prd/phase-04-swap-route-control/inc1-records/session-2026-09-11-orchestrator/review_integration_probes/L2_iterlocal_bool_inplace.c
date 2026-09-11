#include "CQ.h"
int main(void) {
    int acc = 0;
    int r = cq_theta(0, 0.3);
    for (int i = 0; i < 3; ++i) {
        bool c = cq_theta((bool)0, 0.5);
        if (c) r = cq_theta(r, 0.9);
        acc += cq_measure(c);
    }
    return acc + cq_measure(r);
}
