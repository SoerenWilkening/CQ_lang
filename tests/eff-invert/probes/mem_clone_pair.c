/* cq-r6cv (gate 2a review eff-h1 i11), rule 17 at f684858 (cq-4593): two clones communicating through a global;
 * the classical code runs forward, the backend reverses only the gates. */
#include "CQ.h"
double gang;
__attribute__((noinline)) static void fa(unsigned *y, double t) {
    gang = t * 2.0;
    cq_theta(y, t);
}
__attribute__((noinline)) static void fb(unsigned *y) {
    cq_theta(y, gang);
}
int i11(unsigned y0, double th, double t1, double t0) {
    unsigned y = y0;
    cq_theta(&y, th);
    gang = t0;
    cq_invert_begin();
    fa(&y, t1);
    fb(&y);
    cq_invert_end();
    return cq_measure(y);
}
