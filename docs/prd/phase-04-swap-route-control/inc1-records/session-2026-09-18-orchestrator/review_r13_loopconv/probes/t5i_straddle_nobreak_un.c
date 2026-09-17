#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    { int d = (y >> 1); s += cq_measure(d & 1); s += cq_measure(d & 2); }
    { int d = (y >> 2); s += cq_measure(d & 1); s += cq_measure(d & 2); }
    { int d = (y >> 3); s += cq_measure(d & 1); s += cq_measure(d & 2); }
    { int d = (y >> 4); s += cq_measure(d & 1); s += cq_measure(d & 2); }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
