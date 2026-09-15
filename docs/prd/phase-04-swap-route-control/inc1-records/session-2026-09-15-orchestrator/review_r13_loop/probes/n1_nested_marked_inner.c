/* R13-r2 N1 — CONJUNCT (1) READS `L->blocks()`, WHICH INCLUDES SUBLOOP BLOCKS,
   while CONJUNCT (3) reads only `L`'s OWN blocks.  The INNER loop is fully
   iteration-local so `markIfIterationLocal` marks it; the OUTER loop is refused
   (tainted subloop content) and its own body rail `(y>>i)&1` leaks while `y` is
   re-rotated after the loop — the bd `s82e` DIVERGENT class. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 1; i <= 2; ++i) {
        s += cq_measure((y >> i) & 1);
        for (int j = 0; j < 2; ++j) {
            int u = cq_theta(6, 0.4);
            s += cq_measure((u >> j) & 1);
        }
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
