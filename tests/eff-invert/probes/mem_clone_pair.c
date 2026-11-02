/* cq-r6cv (gate 2a review eff-h1 i11): two _adj clones communicating through a global; reversed, fb_adj
 * would read the angle before fa_adj writes it: unimplemented, never a stale angle. */
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
