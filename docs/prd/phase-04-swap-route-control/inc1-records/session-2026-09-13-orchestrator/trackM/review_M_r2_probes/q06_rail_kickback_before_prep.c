/* round 2, item 1(b), take 3 — the region BEFORE the prep is a RAIL kickback
   (block-carrying: Pred/Arm/MergeBB all set), so the prep's `Pred` IS K0's
   `MergeBB`.  Combined with the trailing kickback K1 (whose Pred is the prep's
   MergeBB) the prep carries an INCOMING chain edge, an OUTGOING chain edge and
   the F-M1 edge at once.  Kahn must schedule K1, prep, {K0, select}. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (b0 == 1) { cq_phi(0.7); }        /* K0 — block-carrying, BEFORE the prep */
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }   /* the PREP */
    if (b1) a -= 3;                      /* the merge-phi select */
    if (a == 2) { cq_phi(0.3); }         /* K1 */
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
