#include "CQ.h"
int g_z[3] = {1,2,3};
volatile int g_n = 3;
int slice(void) {
    int Z = 5, N = g_n;            /* runtime trip count, NOT 3 */
    for (int i = 0; i < N; ++i) {
        int q = cq_theta(0, 0.5);
        if (i < 3 && q > 2) { Z -= g_z[i]; }   /* bound is the CLASSICAL guard */
    }
    return cq_measure(Z);
}
