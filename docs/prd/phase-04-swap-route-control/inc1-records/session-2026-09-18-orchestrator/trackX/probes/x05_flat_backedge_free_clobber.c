/* x05_flat_backedge_free_clobber.c — Track X (bd x5fp), session 2026-09-18.
   NEGATIVE CONTROL, NO LOOP: the genuine within-activation §3c clobber the
   fence exists for. The condition reads `q`; the arm rewrites `q`. It must keep
   declining `arm rewrites a condition operand` after any per-activation
   narrowing — a narrowing that moves THIS is the over-accept. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(9, 0.3);
    if (q >= 3) q = q + 3;
    return cq_measure(q);
}
