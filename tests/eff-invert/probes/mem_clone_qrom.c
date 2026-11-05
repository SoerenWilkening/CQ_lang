/* cq-r6cv (gate 2a review eff-h1 i10), rule 17 at f684858 (cq-4593): a clone's classical store into a table a later
 * QROM template of the region reads; the classical code runs forward, the backend reverses only the gates. */
#include "CQ.h"
unsigned char tbl[4];
__attribute__((noinline)) static void setup(unsigned *y, double t, unsigned char v) {
    tbl[1] = v;
    tbl[2] = v;
    cq_theta(y, t);
}
int i10(unsigned x0, unsigned y0, double th, double t1, double p, unsigned char v) {
    unsigned x = x0, y = y0;
    cq_theta(&x, th);
    cq_theta(&y, th);
    tbl[0] = 0; tbl[1] = 0; tbl[2] = 0; tbl[3] = 0;
    cq_invert_begin();
    setup(&y, t1, v);
    if (tbl[x & 3])
        cq_phi(p);
    cq_invert_end();
    return cq_measure(x) + 7 * cq_measure(y);
}
