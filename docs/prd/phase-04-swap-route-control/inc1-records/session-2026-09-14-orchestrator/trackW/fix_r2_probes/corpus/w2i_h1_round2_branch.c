/* R2-I (H-1) — the residual NEITHER the implementer NOR review round 1 built:
   a clause-(c) loop whose SECOND tainted branch exists only at ROUND 2.  `y` is
   a 6.5 classical-call-arm `%out` rail: CLASSICAL when `classifyArms` granted
   clause (c), TAINTED after `repropagateControlMerges`.  The in-loop `if
   ((y>>1)&1)` is therefore claimed by round-2 detection, AFTER the grant. */
#include "CQ.h"
__attribute__((noinline)) int g(int x) { return x * 3; }
int slice(void) {
    int q = cq_theta(5, 0.5);
    int y = 0;
    if (q == 5) y = g(2);
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int  r = cq_theta(7, 0.25);
        bool t = cq_theta((bool)0, 0.4);
        if (t) r = cq_theta(r, 0.2);
        if ((y >> 1) & 1) cq_phi(0.3);
        s += cq_measure(r) + cq_measure(t);
    }
    return s + cq_measure(q);
}
int main(void) { return slice(); }
