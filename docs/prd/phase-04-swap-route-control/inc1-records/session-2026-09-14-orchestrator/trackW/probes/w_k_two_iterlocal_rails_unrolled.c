#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int s = 0;
    { int r = cq_theta(7, 0.25); int t = cq_theta(3, 0.125); if (b) r = cq_theta(r, 0.2); s += cq_measure(r) + cq_measure(t); }
    { int r = cq_theta(7, 0.25); int t = cq_theta(3, 0.125); if (b) r = cq_theta(r, 0.2); s += cq_measure(r) + cq_measure(t); }
    return s + cq_measure(b);
}
int main(void) { return slice(); }
