#include "CQ.h"
int main(void) {
    bool c = cq_theta((bool)0, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        int r = 5;
        if (c) r = cq_theta(5, 0.9);
        acc += cq_measure(r);
    }
    return acc + cq_measure(c);
}
