/* R2-J2 — the failing kernel THIRD, after two passing ones (round 1 built
   `b5_threefn` with the failing one second). */
#include "CQ.h"
int kernel_a(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) { bool t = cq_theta((bool)0, 0.5); int r = cq_theta(7, 0.25);
        if (t) r = cq_theta(r, 0.2); s += cq_measure(r) + cq_measure(t); }
    return s;
}
int kernel_b(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) { bool t = cq_theta((bool)0, 0.6); int r = cq_theta(9, 0.35);
        if (t) r = cq_theta(r, 0.3); s += cq_measure(r) + cq_measure(t); }
    return s;
}
int kernel_c(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) { int u = cq_theta(5, 0.5); int r = cq_theta(7, 0.25);
        if ((u >> 1) & 1) r = cq_theta(r, 0.2); s += cq_measure(r) + cq_measure(u); }
    return s;
}
int main(void) { return kernel_a() + kernel_b() + kernel_c(); }
