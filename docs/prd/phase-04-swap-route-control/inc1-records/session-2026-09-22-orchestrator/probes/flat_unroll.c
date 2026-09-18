#include "CQ.h"
int main(void) {
    int Z = 5; int P = 0; int p[] = {3,2,1}; int z[] = {1,2,3}; bool b0[3];
    if (Z >= z[0]) b0[0] = cq_theta(b0[0], 0.5);
    if (b0[0]) { Z -= z[0]; P += p[0]; }
    if (Z >= z[1]) b0[1] = cq_theta(b0[1], 0.5);
    if (b0[1]) { Z -= z[1]; P += p[1]; }
    if (Z >= z[2]) b0[2] = cq_theta(b0[2], 0.5);
    if (b0[2]) { Z -= z[2]; P += p[2]; }
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(Z) + cq_measure(P);
}
