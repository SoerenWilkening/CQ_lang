// E4 — NESTED loops: the hoisted rail is read in the INNER body, the carried
// handle crosses the INNER back edge. (ii-d)'s "every user inside L" is asked of
// ONE loop; a nested shape is where "which L" can diverge from "which marked
// body".
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[2];
    for (int o = 0; o < 2; o++) {
        for (int i = 0; i < 2; i++) {
            if ((p >> i) & 1) cq_phi(0.2);
        }
        if (a >= 3) b0[o] = cq_theta(b0[o], 0.5);
        if (b0[o]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
