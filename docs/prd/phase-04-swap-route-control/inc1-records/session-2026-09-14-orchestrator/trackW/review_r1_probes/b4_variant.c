/* B4 — F-W1-1 again with a DIFFERENT passing first function (w_d shape: a
   loop-invariant _Bool condition + an iteration-local rotated base). */
#include "CQ.h"
__attribute__((noinline)) int f_pass2(void) {
    bool b = cq_theta((bool)0, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) { int r = cq_theta(7, 0.25); if (b) r = cq_theta(r, 0.2); s += cq_measure(r); }
    return s + cq_measure(b);
}
__attribute__((noinline)) int f_fail(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(5, 0.5); int r = cq_theta(7, 0.25);
        if ((u >> 1) & 1) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(u);
    }
    return s;
}
int main(void) { return f_pass2() + f_fail(); }
