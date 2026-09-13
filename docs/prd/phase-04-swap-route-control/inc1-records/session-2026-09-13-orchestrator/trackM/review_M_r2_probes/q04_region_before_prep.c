/* round 2, item 1(b), take 2 — a BLOCK-CARRYING region (a COMPARE-conditioned
   kickback, not a bare-i1 one) BEFORE the prep, so the prep's `Pred` IS that
   region's `MergeBB`; plus a trailing kickback after the select.  Four regions,
   two sanctioned sequentialChainAlias edges in OPPOSITE directions, and the
   F-M1 edge in the middle. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;                 /* 4.4 compare select (inert) */
    if (a == 2) { cq_phi(0.7); }         /* K0 — BEFORE the prep */
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }   /* the PREP; Pred == K0.MergeBB */
    if (b1) a -= 3;                      /* the merge-phi select */
    if (a == 5) { cq_phi(0.3); }         /* K1 — Pred == prep.MergeBB */
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
