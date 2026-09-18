#include "CQ.h"
static const int g_p[4] = {3,2,1,4};
static const int g_z[4] = {1,2,3,4};
int slice(void) {
    int Z = 5, P = 0;
    for (int i = 0; i < 4; ++i) {
        int q = cq_theta(0, 0.5);
        if (q > 2) { Z -= g_z[i]; P += g_p[i]; }
    }
    return cq_measure(Z) + cq_measure(P);
}
