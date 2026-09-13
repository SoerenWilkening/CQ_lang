/* W4 — the SINKING question the dominance reading depends on: write the rival
   with a flag whose ONLY pre-branch purpose is the arm's rotation, let -O1 fold
   it, and look at WHERE the compare ends up in the stage-1 IR. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0; bool b2 = 0;
    b0 = cq_theta(b0, 0.5);
    if (b0 == 1) a -= 3;
    bool c = (a >= 3);
    if (b0) { b1 = cq_theta(c, 0.5); }
    if (c) { b2 = cq_theta(b2, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2);
}
