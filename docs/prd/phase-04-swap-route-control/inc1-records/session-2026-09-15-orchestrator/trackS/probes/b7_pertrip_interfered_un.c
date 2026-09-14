/* hand-unrolled twin of b7_pertrip_interfered (K=2) */
#include "CQ.h"
int slice(void) {
    int s = 0;
    {   int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1);
        u = cq_theta(u, 0.9);
        s += cq_measure(u); }
    {   int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1);
        u = cq_theta(u, 0.9);
        s += cq_measure(u); }
    return s;
}
int main(void) { return slice(); }
