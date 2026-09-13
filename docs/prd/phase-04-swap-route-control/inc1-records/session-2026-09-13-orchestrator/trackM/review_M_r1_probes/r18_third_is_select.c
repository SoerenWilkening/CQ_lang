/* item 3, CONTROL for r03: identical to r03 except the THIRD construct is a
   DATA SELECT (inert in the hcrg precedence graph, its block fields are null)
   instead of a PhaseKickback (reorderable, and its Pred IS the prep's MergeBB).
   If this ACCEPTS while r03 declines, the r03 decline is the Kahn REORDER
   putting the prep AFTER the select, not anything about the phi. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0; int c = 9;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;
    if (a == 2) c -= 1;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a) + cq_measure(c);
}
