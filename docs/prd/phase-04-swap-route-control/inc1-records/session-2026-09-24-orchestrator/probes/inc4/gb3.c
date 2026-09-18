#include "CQ.h"
int g_z[3] = {1,2,3};
int g_p[3] = {3,2,1};
volatile int g_n = 100;
int slice(void) {
    int Z = 5, P = 0, N = g_n;
    for (int i = 0; i < N; ++i) {
        int q = cq_theta(0, 0.5);
        int j = i < 3 ? i : 0;
        if (q > 2) { Z -= g_z[j]; P += g_p[j]; }
    }
    return cq_measure(Z) + cq_measure(P);
}
