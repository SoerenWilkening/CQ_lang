// D3r — d3_phasearm_only.c plus the TRAILING NON-DIAGONAL gate on q, to ask
// whether the three per-trip `and` rails that BASE/MAIN/TU9QONLY leak (and only
// the COMPOSED binary discharges) are ever left standing across an interference
// on the register they copy.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
