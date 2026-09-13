/* W1 — the rival F2 exists to refuse, written UNFOLDED: the arm rotates the
   condition VALUE itself.  Must still decline after any narrowing. */
#include "CQ.h"
int main(void) {
    int b0 = 0; bool b1 = 0;
    b0 = cq_theta(b0, 0.5);
    bool c = (b0 == 1);
    if (c) { b1 = cq_theta(c, 0.5); }
    return cq_measure(b0) + cq_measure(b1);
}
