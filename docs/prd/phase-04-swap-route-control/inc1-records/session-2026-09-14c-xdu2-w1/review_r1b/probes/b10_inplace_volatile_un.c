#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    volatile int v = 1;
    y ^= v; y ^= v; y ^= v;
    y = cq_theta(y, 0.9);
    return cq_measure(y);
}
int main(void) { return slice(); }
