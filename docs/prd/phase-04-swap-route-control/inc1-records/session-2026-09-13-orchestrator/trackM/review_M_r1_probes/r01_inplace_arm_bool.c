/* item 2 — an in-place Ry ARM (NOT a prep) on a _Bool rail `r` disjoint from the
   condition: the merge phi is [theta(r_old), r_old], so M-beta RAUWs it to a
   CHAINED theta, and condProvenance(phi) drags r_old's pre-rotation name in. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool r = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    r = cq_theta(r, 0.7);               /* r is a live rail */
    if (b0 == 1) { r = cq_theta(r, 0.3); }   /* IN-PLACE ARM, chained */
    if (r) a -= 3;                      /* the select on r's merge phi */
    return cq_measure(b0) + cq_measure(r) + cq_measure(a);
}
