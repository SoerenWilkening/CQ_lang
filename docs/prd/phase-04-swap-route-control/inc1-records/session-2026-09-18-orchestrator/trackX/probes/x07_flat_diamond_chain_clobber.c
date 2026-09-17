/* x07_flat_diamond_chain_clobber.c — Track X (bd x5fp), session 2026-09-18.
   Does a MULTI-OP value chain survive `-O1`'s if-conversion as a real CFG
   diamond?  x05 proved a ONE-op arm does not (it becomes a 4.4 select and
   ACCEPTS, never reaching §3c). This is the flat NEGATIVE control for the
   §3c prong at ArmClassify.cpp:5774 — the within-activation clobber. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(9, 0.3);
    int s = q + 1;                 /* the condition register, derived from q */
    if (s >= 3) { q = q + 3; q = q * 2; q = q ^ 5; q = q + 7; }
    return cq_measure(q) + cq_measure(s);
}
