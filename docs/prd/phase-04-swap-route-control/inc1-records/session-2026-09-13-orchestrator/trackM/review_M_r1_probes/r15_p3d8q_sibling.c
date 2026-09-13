/* The GENUINE 3d8q class through the merge-phi select: TWO SIBLING readers of the
   PRE-rotation name. `c = cq_theta(b1,.25)` consumes b1, and b1 is STILL measured
   afterwards, so `cq_measure(b1)` and `cq_measure(c)` name one physical register
   through two SSA names. Pre-existing P1 hole (bd 3d8q sweeps PURE ops only, so a
   cq_theta/cq_measure reader of a stale name is asked by nothing). */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;
    bool c = cq_theta(b1, 0.25);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(c) + cq_measure(a);
}
