#include "CQ.h"
int main(void) {
    int p = cq_theta(0, 0.3);
    int q = cq_theta(0, 0.7);
    bool c = cq_theta(false, 0.5);
    bool b1 = 0;
    int a;
    if (c) { a = p; } else { a = q; b1 = cq_theta(b1, 0.5); }
    return cq_measure(a) + cq_measure(b1) + cq_measure(p) + cq_measure(q);
}
