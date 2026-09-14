#include "CQ.h"
int slice(void) {
    int q = cq_theta(5, 0.5);
    int r = 0;
    { r = cq_theta(7, 0.25); if (q == 5) r = cq_theta(r, 0.2); }
    { r = cq_theta(7, 0.25); if (q == 5) r = cq_theta(r, 0.2); }
    return cq_measure(r) + cq_measure(q);
}
int main(void) { return slice(); }
