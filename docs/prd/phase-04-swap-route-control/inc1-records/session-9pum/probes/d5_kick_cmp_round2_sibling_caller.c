#include "CQ.h"
int ext_f(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    int x = (y != 0);
    int b = cq_theta(x, 0.25);
    int b3 = cq_theta(x, 0.9);     /* the SIBLING — BEFORE the branch */
    if (b > 0) cq_phi(0.7);
    return cq_measure(b3) + keep;
}
int main(void){ (void)slice(); return 0; }
