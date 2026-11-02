#include "CQ.h"
/* tests/loops-classical (cq-djnk, cq-9o04): kept rails after a classically bounded loop that writes memory.
 * k_hist (review loopscl-h2 p28): a QRAM histogram, h[1] read after the loop, no gate after it: the reverse loop
 * pops the stores after the read; only the measured values stay.
 * k_whole: every rail the loop stores lands in its own cell and every cell is measured (179's shape with fixed
 * measured cells): the whole object is kept, nothing else. */
int k_hist(unsigned x0, double th, double th2) {
    unsigned x = x0;
    cq_theta(&x, th);
    int h[4] = {0};
    for (int i = 0; i < 4; i++)
        h[(x >> 2 * i) & 3]++;
    int s = h[1];
    cq_theta(&x, th2);
    return cq_measure(s) + cq_measure(x);
}
unsigned k_whole(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned y[4];
    for (int i = 0; i < 4; i++)
        y[i] = ((x >> i) & 1) ^ ((x >> (i + 4)) & 1);
    return cq_measure(y[0]) | cq_measure(y[1]) << 1 | cq_measure(y[2]) << 2 | cq_measure(y[3]) << 3;
}
