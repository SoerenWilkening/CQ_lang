/* cq-r6cv (gate 2a review eff-h1 i12), rule 17 at f684858 (cq-4593): a clone reading a global a later classical
 * store of the region overwrites; the classical code runs forward, the backend reverses only the gates. */
#include "CQ.h"
double gang;
__attribute__((noinline)) static void fd(unsigned y) {
    if (y > 3u)
        cq_phi(gang);
}
int i12(unsigned y0, double th, double t1, double t0) {
    unsigned y = y0;
    cq_theta(&y, th);
    gang = t0;
    cq_invert_begin();
    fd(y);
    gang = t1;
    cq_invert_end();
    return cq_measure(y);
}
