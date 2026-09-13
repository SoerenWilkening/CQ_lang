/* W3 — the rival with the rotated flag `c` consumed as DATA only (measured,
   never a branch condition).  The discriminator for "exclude only flags that
   are a conditional branch's condition". */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    b0 = cq_theta(b0, 0.5);
    if (b0 == 1) a -= 3;
    bool c = (a >= 3);
    if (b0) { b1 = cq_theta(c, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(c) + cq_measure(a);
}
