#include "CQ.h"
/* F x P adversarial: a FURTHER non-diagonal gate on the phi leaf's own wire
   between the prep and the kickback.  The kickback must read the POST-gate
   register; the emitted order is positional, so source order must be preserved. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    b1 = cq_theta(b1, 0.2);
    if (b1 && b0) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1);
}
