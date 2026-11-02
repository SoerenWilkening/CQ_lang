/* cq-c969 (gate 2a review unc-h3 p12), rule 17 at f684858 (cq-4593): a clone call rotating the register between a
 * region template reading it and that template's uncompute (rule 5); lowered as anywhere else, the backend
 * reverses the region. */
#include "CQ.h"
__attribute__((noinline)) static void rot(int *p, double t) { cq_theta(p, t); }
int p12(int a, double t1, double t2) {
    int x = a;
    rot(&x, t1);
    cq_invert_begin();
    int t = x & 3;
    rot(&x, t2);
    if (t == 1) cq_phi(1.0);
    cq_invert_end();
    return cq_measure(x);
}
