/* ATTACK B2 on the c2 conversion: ONE-OPERAND DELTA = the `y & 1` rail is NOT
   measured — it accumulates, so it is a COHERENT which-path record of `y` when
   the post-loop gate fires on `y`.  This removes clause (ii-c)'s own premise. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1) + (y & 1);   /* <-- the delta: no cq_measure */
        u = cq_theta(u, 0.9);
        s += cq_measure(u);
    }
    y = cq_theta(y, 0.7);
    return cq_measure(s) + cq_measure(y);
}
int main(void) { return slice(); }
