#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    int last = 0;
    last = (y > 1); s += cq_measure(last);
    last = (y > 2); s += cq_measure(last);
    y = cq_theta(y, 0.9);
    return s + cq_measure(last) + cq_measure(y);
}
int main(void) { return slice(); }
