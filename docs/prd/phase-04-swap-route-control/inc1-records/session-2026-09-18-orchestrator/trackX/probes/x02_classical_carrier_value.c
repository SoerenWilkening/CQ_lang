/* x02_classical_carrier_value.c — Track X (bd x5fp), session 2026-09-18.
   WITNESS CANDIDATE 1. The back-edge path from the condition to the routed base
   runs through a CLASSICAL carried variable (`cq_measure` is the taint SINK), so
   NO tainted value crosses the back edge and the loop layer's X1
   (`kMsgCrossIter`) has nothing to refuse. Both quantum registers are
   ITERATION-LOCAL (fresh source thetas per trip).
     condProvenance(icmp %q, %a_phi) walks the CLASSICAL %a_phi (untainted values
     are traversed, only tainted ones collected) -> its latch incoming, the
     measure result -> %r's merge phi -> %r_src == Routed == StraightThrough.
   Within one activation the flag is minted from %q/%a_phi BEFORE the arm writes
   %r, so the overlap exists only around the back edge. */
#include "CQ.h"
int main(void) {
    int a = 0;                        /* CLASSICAL, loop-carried */
    for (int i = 0; i < 3; ++i) {
        int q = cq_theta(9, 0.3);     /* fresh condition rail per trip */
        int r = cq_theta(7, 0.2);     /* fresh routed rail per trip */
        if (q >= a) r = r + 3;        /* VALUE arm on r */
        a = cq_measure(r);            /* classical: closes the back edge */
    }
    return a;
}
