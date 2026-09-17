/* t16 unrolled — the HAND-UNROLLED twin of t16_rolled (no loop, no carried phi,
 * so no promotion).  Its trace is the witness of record for the rolled form. */
#include "CQ.h"
int main(void) {
    short a = 5;
    bool b0[3];
    b0[0] = cq_theta(b0[0], 0.5);
    if (b0[0]) a -= 3;
    b0[1] = cq_theta(b0[1], 0.5);
    if (b0[1]) a -= 3;
    b0[2] = cq_theta(b0[2], 0.5);
    if (b0[2]) a -= 3;
    return (int)cq_measure(a);
}
