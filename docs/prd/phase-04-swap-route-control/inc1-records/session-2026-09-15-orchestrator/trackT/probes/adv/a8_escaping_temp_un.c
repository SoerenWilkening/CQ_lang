#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int t = 0;
    t = (y >> 1) & 1;
    t = (y >> 2) & 1;
    y = cq_theta(y, 0.9);
    return cq_measure(t) + cq_measure(y);
}
int main(void) { return slice(); }
