/* item 5, take 2 — r06's shape with the fall-through value of `y` made OPAQUE so
   `clang -O1` cannot fuse the two guards. `y` is a 6.5 classical-call-arm %out
   rail: UNTAINTED in round 1, tainted only by repropagateControlMerges. So the
   b1-prep diamond is NOT a claimed region in round 1, while the select's
   condition (the prep merge phi) IS tainted in round 1. */
#include "CQ.h"
int ext_f(int a);
int slice(void) {
    volatile int yv = 1;
    int a = 5;
    int q = 3; q = cq_theta(q, 0.5);
    int y = yv;
    if (q > 5) y = ext_f(7);                 /* 6.5 classical call arm -> %out */
    bool b1 = 0;
    if (y > 3) { b1 = cq_theta(b1, 0.5); }   /* prep under a %out-derived cond */
    if (b1) a -= 3;                          /* the select on the merge phi */
    return cq_measure(a) + cq_measure(b1) + cq_measure(q);
}
int main(void) { return slice(); }
