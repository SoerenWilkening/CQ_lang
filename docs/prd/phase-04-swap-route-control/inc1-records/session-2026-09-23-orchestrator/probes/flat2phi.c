#include "CQ.h"
int g_p[3] = {3,2,1};
int g_z[3] = {1,2,3};
int slice(int i) {
    int Z = 5, P = 0;
    bool b = 0;
    if (Z >= g_z[i]) b = cq_theta(b, 0.5);
    if (b) { Z -= g_z[i]; P += g_p[i]; }
    return cq_measure(Z) + cq_measure(P);
}
