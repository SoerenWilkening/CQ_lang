/* round 2, item 1(c) — TWO merge-phi selects on ONE prep phi: two edges out of
   the same prep node.  Plus a trailing kickback so the Kahn reorder is live. */
#include "CQ.h"
int main(void) {
    int a = 5; int c = 9; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }   /* the PREP */
    if (b1) a -= 3;                            /* select #1 on the phi */
    if (b1) c -= 1;                            /* select #2 on the SAME phi */
    if (a == 2) { cq_phi(0.3); }               /* trailing kickback */
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a) + cq_measure(c);
}
