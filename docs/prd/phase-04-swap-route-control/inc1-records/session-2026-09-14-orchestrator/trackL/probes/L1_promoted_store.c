/* L1_promoted_store.c — Track L, 2026-09-14. READ-ONLY probe on ORACLE f7b65d8c (59ac5b7).
   The post-promotion shape as SOURCE: exactly ONE store per trip, of the merge value,
   at the trip's end — the shape the L-1a carve produces before the type rewrite. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b[3] = {0};
    for (int i = 0; i < 3; ++i) {
        bool t = 0;
        if (a >= 3) t = cq_theta(t, 0.5);
        if (t) a -= 3;
        b[i] = t;
    }
    int s = cq_measure(a);
    for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
    return s;
}
