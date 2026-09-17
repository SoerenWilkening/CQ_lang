/* SUBJECT (C) ATTACK — THE SHAPE THAT DEFEATS THE ATOMICITY ARGUMENT, WITH A
   BREAK THE RUNTIME TAKES.  `t5b_break_split.c` put a second gate group after
   the break test so `-O1` cannot if-convert the body into one block, but its
   break is measure-derived and it declines at bd 3d8q.  Here the predicate is
   classical, so if this ACCEPTS the body spans blocks AND the break fires. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        s += cq_measure((y >> k) & 1);
        if (k >= lim) break;                     /* CLASSICAL — taken at k == 2 */
        s += cq_measure((y >> (k + 8)) & 1);
        s += cq_measure((y >> (k + 16)) & 1);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
