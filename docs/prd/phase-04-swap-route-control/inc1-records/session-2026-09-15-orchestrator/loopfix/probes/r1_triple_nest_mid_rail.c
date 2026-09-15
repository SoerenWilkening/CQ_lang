/* RE-ATTACK 1 (Rule 13, this fix's own round) — THREE LEVELS.  The INNERMOST loop
   is fully iteration-local (marked); the MIDDLE loop has its own body rail
   `(y>>j)&1`; the OUTER has none of its own.  Before the fix, `L_mid` exited
   conjunct (1) on `L_inner`'s marking.  After it, `L_mid`'s OWN blocks decide. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 0; i < 2; ++i)
        for (int j = 1; j <= 2; ++j) {
            s += cq_measure((y >> j) & 1);
            for (int k = 0; k < 2; ++k) {
                int u = cq_theta(6, 0.4);
                s += cq_measure((u >> k) & 1);
            }
        }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
