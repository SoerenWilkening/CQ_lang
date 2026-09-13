/* round 2, item 1(d) — the ROUND-2 window with a THIRD region AFTER the select,
   so a round-2 plan would hold >= 2 regions and a stale round-1 `PrepRegionIdx`
   would index the wrong one.  r20's shape + `if (a == 2) cq_phi(0.3);`. */
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
    if (a == 2) { cq_phi(0.3); }             /* THIRD region, after the select */
    return cq_measure(a) + cq_measure(b1) + cq_measure(q);
}
int main(void) { return slice(); }
