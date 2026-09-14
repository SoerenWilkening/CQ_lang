/* w_l's HAND-UNROLLED twin, statement for statement, K = 2. */
#include "CQ.h"
int f_c(void) {
    int s = 0;
    { bool t = cq_theta((bool)0, 0.5); int r = cq_theta(7, 0.25); if (t) r = cq_theta(r, 0.2); s += cq_measure(r) + cq_measure(t); }
    { bool t = cq_theta((bool)0, 0.5); int r = cq_theta(7, 0.25); if (t) r = cq_theta(r, 0.2); s += cq_measure(r) + cq_measure(t); }
    return s;
}
int f_b(void) {
    int r = cq_theta(7, 0.25);
    bool b = cq_theta((bool)0, 0.5);
    { if (b) r = cq_theta(r, 0.2); }
    { if (b) r = cq_theta(r, 0.2); }
    return cq_measure(r) + cq_measure(b);
}
int main(void) { return f_c() + f_b(); }
