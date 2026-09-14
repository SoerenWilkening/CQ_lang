#include "CQ.h"
__attribute__((noinline)) int f_fail1(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(5, 0.5); int r = cq_theta(7, 0.25);
        if ((u >> 1) & 1) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(u);
    }
    return s;
}
__attribute__((noinline)) int f_fail2(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.5); int r = cq_theta(9, 0.25);
        if ((u >> 1) & 1) r = cq_theta(r, 0.3);
        s += cq_measure(r) + cq_measure(u);
    }
    return s;
}
int main(void) { return f_fail1() + f_fail2(); }
