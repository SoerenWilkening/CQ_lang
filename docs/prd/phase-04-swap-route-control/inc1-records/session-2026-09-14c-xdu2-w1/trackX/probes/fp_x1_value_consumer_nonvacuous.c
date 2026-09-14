#include "CQ.h"
/* F x P, the VALUE consumer, with NON-VACUOUS support: b1 is prepared on the
   POSITIVE b0 branch, so |b0=1,b1=1> has amplitude sin^2(0.25) != 0 and the
   merged arm actually fires.  m28 (the gate's value witness) prepares b1 on the
   NEGATED branch, so b1 ^ b0 has ZERO amplitude there. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    int a = 9;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1 && b0) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
