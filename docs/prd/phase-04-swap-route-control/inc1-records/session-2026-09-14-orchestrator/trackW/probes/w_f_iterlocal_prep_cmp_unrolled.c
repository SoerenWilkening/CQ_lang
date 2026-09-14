#include "CQ.h"
int slice(void) {
    int q = cq_theta(5, 0.5);
    int s = 0;
    { int r = 7; if (q == 5) r = cq_theta(7, 0.2); s += cq_measure(r); }
    { int r = 7; if (q == 5) r = cq_theta(7, 0.2); s += cq_measure(r); }
    return s + cq_measure(q);
}
int main(void) { return slice(); }
