#include "CQ.h"
int g_z[3] = {1,2,3};
int g_p[3] = {3,2,1};
volatile int g_n = 3;
int slice(void) {
    int Z = 5, P = 0, N = g_n;
    for (int i = 0; i < N; ++i) {
        int q = cq_theta(0, 0.5);
        if (i < 3 && q > 2) { Z -= g_z[i]; P += g_p[i]; }
    }
    return cq_measure(Z) + cq_measure(P);
}
