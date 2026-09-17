/* ATTACK B1 on the c2 conversion: ONE-OPERAND DELTA = a POST-LOOP NON-DIAGONAL
   GATE ON `y`, the register the HOISTED, LEFT-ALLOCATED `y & 1` rail copies.
   c2 as shipped has no such gate; this is the shape the fence exists for. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1) + cq_measure(y & 1);
        u = cq_theta(u, 0.9);
        s += cq_measure(u);
    }
    y = cq_theta(y, 0.7);          /* <-- the delta */
    return s + cq_measure(y);
}
int main(void) { return slice(); }
