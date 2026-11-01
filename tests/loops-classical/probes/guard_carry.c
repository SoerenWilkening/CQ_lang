#include "CQ.h"
/* cq-r8-d (185): a guarded quantum accumulator loop whose deferred reverse is placed at the return, after
 * later loops: the guard "the loop ran" and the seed it frees are carried over joins whose phis the
 * construction is still filling (SSAUpdater read them as poison). */
int g_carry(int nk, int t, double th) {
    _Bool k[nk];
    for (int i = 0; i < nk; i++) k[i] = 0;
    for (int i = 0; i < nk; i++) cq_theta(&k[i], th);
    int kv = 0;
    for (int i = 0; i < nk; i++) kv |= k[i] << i;
    double a = (double)kv;
    for (int j = 0; j < t; j++)
        if (k[0]) cq_phi(a * (double)(1 << j));
    int out = 0;
    for (int i = 0; i < nk; i++) out |= cq_measure(k[i]) << i;
    return out;
}
