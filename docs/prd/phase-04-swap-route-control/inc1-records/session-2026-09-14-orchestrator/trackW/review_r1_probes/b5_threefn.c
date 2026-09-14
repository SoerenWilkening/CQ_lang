/* B5 — pass, an unrelated function, then fail. */
#include "CQ.h"
__attribute__((noinline)) int f_pass(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        bool t = cq_theta((bool)0, 0.5); int r = cq_theta(7, 0.25);
        if (t) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(t);
    }
    return s;
}
__attribute__((noinline)) int f_mid(int x) { return x * 3 + 1; }
__attribute__((noinline)) int f_fail(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(5, 0.5); int r = cq_theta(7, 0.25);
        if ((u >> 1) & 1) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(u);
    }
    return s;
}
int main(void) { return f_pass() + f_mid(2) + f_fail(); }
