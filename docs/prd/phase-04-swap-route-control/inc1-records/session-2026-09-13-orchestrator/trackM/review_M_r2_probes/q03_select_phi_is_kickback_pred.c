/* round 2, item 1(c) second half — the select's phi region is ALSO the region a
   FOLLOWING kickback's Pred names (F-M1's own shape, r03) *and* a further
   kickback after that, so the prep carries TWO outgoing edges of two kinds. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }   /* the PREP */
    if (b1) a -= 3;                            /* the merge-phi select */
    if (a == 2) { cq_phi(0.3); }               /* kickback 1 (Pred = prep merge) */
    if (b0 == 1) { cq_phi(0.9); }              /* kickback 2 */
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
