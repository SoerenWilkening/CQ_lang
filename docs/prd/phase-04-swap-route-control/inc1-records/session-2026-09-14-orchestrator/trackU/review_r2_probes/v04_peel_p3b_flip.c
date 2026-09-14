/* R2 lead 3: MergePhiPeel P3b REFUSES to peel a phi with an undef/poison
   incoming (a deliberate decline-keeping gate).  The z9t1 normalizer rewrites
   undef incomings of any phi carrying the theta's result -> those phis now
   PASS P3b.  Here the undef belongs to a DIFFERENT C object (`t`), not to the
   theta's own seed object, and `t` is undefined on ONE edge only. */
#include "CQ.h"
int main(void) {
    bool s;                     /* uninitialized -> undef seed */
    bool q = cq_theta(s, 0.5);  /* theta in ENTRY: dominates the branch */
    bool t;                     /* a DIFFERENT uninitialized object */
    int  y = 7;
    if (q) { t = q; y = 9; }    /* 2 merge phis; t's pred incoming is undef */
    return cq_measure(t) + cq_measure(y);
}
