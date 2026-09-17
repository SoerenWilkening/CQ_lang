// H2 — H1 with zujr's CARRIED HANDLE added (a value arm on a scalar bool rail):
// the multi-exit question asked of the composition rather than of tu9q alone.
#include "CQ.h"
int slice(int u, int lim) {
    int q = cq_theta(u, 0.5);
    int r = cq_theta(u, 0.3);
    int p = q * 3;
    int a = 5;
    for (int i = 0; i < 3; i++) {
        if (i >= lim) break;
        if ((p >> i) & 1) cq_phi(0.2);
        r = cq_theta(r, 0.1);
        if (r >= 0) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(r) + cq_measure(a);
}
int main(int argc, char **argv) { (void)argv; return slice(4, argc + 1); }
