#include "CQ.h"
int slice(void) {
    int s = 0;
    { bool t = cq_theta((bool)0, 0.5); int r = cq_theta(7, 0.25); if (t) r = cq_theta(r, 0.2); s += cq_measure(r & 3) + cq_measure(t); }
    { bool t = cq_theta((bool)0, 0.5); int r = cq_theta(7, 0.25); if (t) r = cq_theta(r, 0.2); s += cq_measure(r & 3) + cq_measure(t); }
    return s;
}
int main(void) { return slice(); }
