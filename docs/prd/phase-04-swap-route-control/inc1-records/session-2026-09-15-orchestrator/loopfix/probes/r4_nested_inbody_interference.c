/* RE-ATTACK 5 (Rule 13) — THE COMPOSITION WITH TRACK S′'s DROPPED `L->contains`
   SKIP: the interfering CHAINED rotation sits INSIDE the outer body, after the
   inner loop, rather than after the whole nest.  Conjunct (2) must still find it
   now that conjunct (1) lets the outer loop through. */
#include "CQ.h"
int slice(void) {
    int s = 0;
    int y = cq_theta(5, 0.5);
    for (int i = 1; i <= 2; ++i) {
        s += cq_measure((y >> i) & 1);
        for (int j = 0; j < 2; ++j) {
            int u = cq_theta(6, 0.4);
            s += cq_measure((u >> j) & 1);
        }
        y = cq_theta(y, 0.9);
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
