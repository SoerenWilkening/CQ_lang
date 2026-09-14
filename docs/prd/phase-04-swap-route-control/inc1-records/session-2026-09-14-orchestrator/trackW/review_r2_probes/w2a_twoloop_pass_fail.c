/* R2-A — THE AXIS THE THREE NEW FIXTURES DO NOT COVER: ONE function whose TWO
   loops want DIFFERENT verdicts.  Loop 1 is `w_i` (clause (c), re-ask PASSES);
   loop 2 is `w_j` (clause (c), conjunct 2 MUST decline).  `AskedEscape` /
   `AskedMarking` are per-FUNCTION sets keyed on the loop HEADER, so this is the
   in-function analogue of F-W1-1's cross-function suppression. */
#include "CQ.h"
int slice(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {                 /* loop 1 — PASSES */
        bool t = cq_theta((bool)0, 0.5);
        int r = cq_theta(7, 0.25);
        if (t) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(t);
    }
    for (int k = 0; k < 2; ++k) {                 /* loop 2 — MUST DECLINE */
        int u = cq_theta(5, 0.5);
        int r = cq_theta(7, 0.25);
        if ((u >> 1) & 1) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(u);
    }
    return s;
}
int main(void) { return slice(); }
