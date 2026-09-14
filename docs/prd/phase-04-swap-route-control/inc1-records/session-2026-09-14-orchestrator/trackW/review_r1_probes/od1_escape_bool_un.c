#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = 0;
    r = cq_theta(7, 0.25); if (b) r = cq_theta(r, 0.2);
    r = cq_theta(7, 0.25); if (b) r = cq_theta(r, 0.2);
    return cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
