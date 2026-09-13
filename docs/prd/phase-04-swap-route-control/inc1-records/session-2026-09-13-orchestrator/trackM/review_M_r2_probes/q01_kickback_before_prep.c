/* round 2, item 1(b) — a FOURTH, BLOCK-CARRYING region BEFORE the prep, so the
   prep's `Pred` IS that region's `MergeBB` (the sanctioned sequentialChainAlias
   in the OTHER direction), on top of r03's trailing kickback.
   Expected precedence graph: Precedes[prep]={K0} (prep before K0, because prep
   names K0's doomed MergeBB as its Pred), Precedes[K1]={prep} (K1 before prep),
   Precedes[prep]+={select} (the F-M1 edge).  Kahn must therefore emit
   K1, prep, then {K0, select}.  The question is whether the stream is still in
   SOURCE order (every emitter inserts positionally) and 2b-clean. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;                 /* 4.4 compare select: a := {2,5} */
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }   /* the PREP (InPlaceRotation) */
    if (b1) { cq_phi(0.7); }             /* K0: a kickback on the SAME phi */
    if (a == 2) { cq_phi(0.3); }         /* K1: Pred is the prep's MergeBB */
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
