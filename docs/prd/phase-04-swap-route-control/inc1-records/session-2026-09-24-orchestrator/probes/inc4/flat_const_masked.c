#include "CQ.h"
static const int c_p[4] = {3,2,1,0};
static const int c_z[4] = {1,2,3,4};
int slice(int i) {
    int Z = 5, P = 0;
    int j = i & 3;
    int q = cq_theta(0, 0.5);
    if (q > 2) { Z -= c_z[j]; P += c_p[j]; }
    return cq_measure(Z) + cq_measure(P);
}
