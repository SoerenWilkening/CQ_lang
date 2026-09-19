/* G-13 standing probe, ROLLED: the owner's program + a trailing NON-DIAGONAL
   gate on every register the condition reads (Z, and the b0 rail). */
#include "CQ.h"
int main(void) {
    int Z = 5; int P = 0; int n = 3;
    int p[] = {3, 2, 1}; int z[] = {1, 2, 3};
    bool b0[n];
    for (int i = 0; i < n; ++i) {
        if (Z >= z[i]) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) { Z -= z[i]; P += p[i]; }
    }
    Z     = cq_theta(Z, 0.3);      /* trailing non-diagonal on the condition's register */
    b0[0] = cq_theta(b0[0], 0.7);  /* trailing non-diagonal on the rail */
    int x[n];
    for (int i = 0; i < n; ++i) x[i] = cq_measure(b0[i]);
    return cq_measure(Z) + cq_measure(P);
}
