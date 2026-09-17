/* x08_inloop_chain_backedge_clobber.c — Track X (bd x5fp), session 2026-09-18.
   WITNESS CANDIDATE 2 — the one that could reach the §3c prong at
   ArmClassify.cpp:5774 (the prong whose OUTER test gates an ACCEPT; the
   :5903 twin declines on BOTH branches, so no narrowing there can ever
   produce one).  A multi-op value chain (so `-O1` keeps the diamond), an
   ITERATION-LOCAL routed rail, and the back edge closed through a CLASSICAL
   carrier (`cq_measure` is the taint sink), so no tainted value crosses it. */
#include "CQ.h"
int main(void) {
    int a = 0;                            /* CLASSICAL, loop-carried */
    for (int i = 0; i < 3; ++i) {
        int q = cq_theta(9, 0.3);         /* fresh condition rail per trip */
        int r = cq_theta(7, 0.2);         /* fresh routed rail per trip */
        if (q >= a) { r = r + 3; r = r * 2; r = r ^ 5; r = r + 7; }
        a = cq_measure(r);                /* classical: closes the back edge */
    }
    return a;
}
