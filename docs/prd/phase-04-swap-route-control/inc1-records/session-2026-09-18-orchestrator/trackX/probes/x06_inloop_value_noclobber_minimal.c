/* x06_inloop_value_noclobber_minimal.c — Track X (bd x5fp), session 2026-09-18.
   The SMALLEST in-loop VALUE arm with no clobber anywhere: one fresh condition
   rail, one fresh routed rail, nothing carried at all. It isolates "does an
   in-loop value arm lower AT ALL today?" — the question that decides whether
   the §3c per-activation narrowing has any reachable accept. */
#include "CQ.h"
int main(void) {
    int t = 0;
    for (int i = 0; i < 3; ++i) {
        int q = cq_theta(9, 0.3);
        int r = cq_theta(7, 0.2);
        if (q >= 5) r = r + 3;
        t += cq_measure(r);
    }
    return t;
}
