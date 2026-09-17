/* ATTACK A4 on the c1 conversion: THE RAIL'S BORROWED PARENT IS GATED INSIDE THE
   BODY.  `y` — the register every compare rail copies — is re-rotated per trip,
   so a rail minted on trip 1 stands at a non-diagonal gate fired on trip 2. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) { s += cq_measure(y > k); y = cq_theta(y, 0.9); }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
