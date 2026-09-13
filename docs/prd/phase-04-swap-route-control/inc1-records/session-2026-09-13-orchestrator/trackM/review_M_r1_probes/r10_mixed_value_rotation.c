/* item 2 — the ONE shape where rung 0's disjunction could outrun the emitter's
   dispatch: ClassArm == Value on one arm and ClassArmFalse == InPlaceRotation on
   the other. `emitRegion` dispatches Value FIRST (SwapRouteEmit.cpp:1198), which
   RAUWs the merge to a SelectInst, not a theta call. classifyArms is claimed to
   refuse it as `mixed phase/value arm` — MEASURE, do not assume (Rule 11). */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); } else { b1 = !b1; }
    if (b1) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
