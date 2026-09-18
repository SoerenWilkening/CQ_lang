#include "CQ.h"
int main(void) {
    int Z = 5;
    int P = 0;
    int n = 3;
    int p[] = {3, 2, 1};
    int z[] = {1, 2, 3};
    bool b0[n];
    for (int i = 0; i < n; ++i) {
        if (Z >= z[i]) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) {
            Z -= z[i];
            P += p[i];
        }
    }
    return cq_measure(b0[0]) + cq_measure(b0[1])  + cq_measure(b0[2]) + cq_measure(Z)  + cq_measure(P);
}
