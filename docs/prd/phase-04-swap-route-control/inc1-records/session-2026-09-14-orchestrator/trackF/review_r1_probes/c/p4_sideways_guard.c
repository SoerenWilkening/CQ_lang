#include "CQ.h"
/* p4 — SIDEWAYS/DOWNWARD COMPARE REWRITE.  The guard for region 3 is written in
   the source against the PRE-region-2 register `pre`, NOT against the post-region
   `a`.  If -O1 rewrites it onto `a` (= select(M2,...)) it becomes a phi
   descendant of region 2's own merge phi and Track F's conjunct drops it. */
int main(void) {
    int a = 5;
    bool b0 = 0, b1 = 0, b2 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0) a -= 3;
    int pre = a;                       /* pre-region-2 value of a */
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }   /* REGION 2 */
    if (b1) a -= 3;
    if (pre >= 3) { b2 = cq_theta(b2, 0.5); } /* guard on `pre`, not on `a` */
    return cq_measure(b0)+cq_measure(b1)+cq_measure(b2)+cq_measure(a);
}
