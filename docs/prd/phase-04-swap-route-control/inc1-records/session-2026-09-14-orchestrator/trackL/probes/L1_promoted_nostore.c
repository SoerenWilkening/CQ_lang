/* L1_promoted_nostore.c — Track L, 2026-09-14. READ-ONLY probe on ORACLE f7b65d8c (59ac5b7).
   THE PEEL BEHIND THE STORE. This is a_loop_n3's body AFTER the per-activation cell
   promotion the L-1a carve must perform: the seed is the initializer constant, the
   cell's value across the diamond is an SSA merge phi, and there is NO store at all.
   QUESTION: with the store removed, is the rolled cascade body lowerable today? */
#include "CQ.h"
int main(void) {
    int a = 5;
    for (int i = 0; i < 3; ++i) {
        bool t = 0;
        if (a >= 3) t = cq_theta(t, 0.5);
        if (t) a -= 3;
    }
    return cq_measure(a);
}
