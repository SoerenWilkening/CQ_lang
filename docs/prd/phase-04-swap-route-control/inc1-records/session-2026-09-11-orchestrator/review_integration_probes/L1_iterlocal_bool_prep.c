#include "CQ.h"
int main(void) {
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        bool c = cq_theta((bool)0, 0.5);
        int r = 5;
        if (c) r = cq_theta(5, 0.9);
        acc += cq_measure(r) + cq_measure(c);
    }
    return acc;
}
