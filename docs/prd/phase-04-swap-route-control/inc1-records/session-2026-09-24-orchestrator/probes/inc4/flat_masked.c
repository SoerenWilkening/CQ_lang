#include "CQ.h"
int g_p[4] = {3,2,1,0};
int g_z[4] = {1,2,3,4};
int slice(int i) {
    int Z = 5, P = 0;
    int j = i & 3;                 /* PROVABLY in [0,3] for a [4 x i32] table */
    int q = cq_theta(0, 0.5);
    if (q > 2) { Z -= g_z[j]; P += g_p[j]; }
    return cq_measure(Z) + cq_measure(P);
}
