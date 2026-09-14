#include "CQ.h"
int slice(void) {
    int r = cq_theta(7, 0.25);
    { bool b = cq_theta((bool)0, 0.5); if (b) r = cq_theta(r, 0.2); }
    { bool b = cq_theta((bool)0, 0.5); if (b) r = cq_theta(r, 0.2); }
    return cq_measure(r);
}
int main(void) { return slice(); }
