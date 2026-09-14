#include "CQ.h"
/* BRIEF item 7: the implementer claims "at the KICKBACK at most ONE phi leaf can
   ever satisfy the in-Pred requirement, because two distinct diamonds have two
   distinct merge blocks".  ATTACK: -O1 FUSES two same-condition regions into ONE
   diamond whose merge block carries TWO phis (bd b6ap).  Both are then in Pred. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    bool b2 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); b2 = cq_theta(b2, 0.9); }
    if (b1 && b2) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2);
}
