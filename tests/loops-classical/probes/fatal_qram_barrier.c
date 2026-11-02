#include "CQ.h"
/* tests/loops-classical fatal probe (cq-9o04, review loopscl-h2 p29): a QRAM histogram filled in a classically
 * bounded loop, an Ry on x (which the reverse loop reads) after the loop, then a read of h[0]. The reverse loop pops
 * the QRAM stores: it may run neither before the read (the read saw the popped cells: zeros) nor after the Ry.
 * cq::unimplemented. */
int p29(unsigned x0, double th, double th2) {
    unsigned x = x0;
    cq_theta(&x, th);
    int h[4] = {0};
    for (int i = 0; i < 4; i++)
        h[(x >> 2 * i) & 3]++;
    cq_theta(&x, th2);
    return cq_measure(h[0]) + cq_measure(x);
}
