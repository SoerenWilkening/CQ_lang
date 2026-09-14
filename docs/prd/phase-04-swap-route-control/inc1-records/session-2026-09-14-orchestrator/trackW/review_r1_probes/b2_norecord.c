#include "CQ.h"
__attribute__((noinline)) int f_nrec(void) {   /* clause (b') — no (c) record */
    int r = cq_theta(7, 0.25);
    bool b = cq_theta((bool)0, 0.5);
    for (int k = 0; k < 2; ++k) { if (b) r = cq_theta(r, 0.2); }
    return cq_measure(r) + cq_measure(b);
}
__attribute__((noinline)) int f_fail(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(5, 0.5);
        int r = cq_theta(7, 0.25);
        if ((u >> 1) & 1) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(u);
    }
    return s;
}
int main(void) { return f_nrec() + f_fail(); }
