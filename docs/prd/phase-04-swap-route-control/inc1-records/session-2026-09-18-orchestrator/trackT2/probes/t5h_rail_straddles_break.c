/* SUBJECT (C) — THE SHAPE THAT SHOULD DEFEAT THE POST-DOMINANCE CLAUSE.
   The rail `d = y >> k` is USED IN BOTH body blocks (`d & 1` before the classical
   early exit, `d & 2` after it), so `-O1` cannot sink the mint past the break and
   the free point (after the LAST use) lands in the block the break SKIPS.
   `Uncomputation` §4 then asks `PDT.dominates(At->block, G->block)` across a
   break edge, which is the only place that clause can be load-bearing. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        s += cq_measure(d & 1);            /* use 1 — block A, before the exit */
        if (k >= lim) break;               /* CLASSICAL early exit */
        s += cq_measure(d & 2);            /* use 2 — block B, after the exit */
    }
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
