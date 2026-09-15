/* GROUP-GATE probe G1 — the adversarial completion of Track T's bd `1yeu`
   two-function probe `r2_two_functions.c`.
   That probe's `kb()` half leaks three rails (the hoisted TEMPLATE rail `p`
   and its two per-trip shifts) which its hand-unrolled twin discharges — and
   that is BENIGN there only because `kb()` ends in a MEASURE, so nothing
   interferes with `y` afterwards (Rule 6's accepted leak).
   THIS probe adds the one line that makes it NOT benign: a post-loop
   non-diagonal gate on the very register those rails copy. Per CLAUDE.md §5
   (bd `s82e` / Q-R1-1) that is the WRONG-UNITARY half, and
   `declineDephasingUnmarkedLoopRails` MUST refuse it. */
#include "CQ.h"
int ka(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    s += cq_measure((y >> 1) & 1); s += cq_measure((y >> 2) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int kb(void) {
    int y = cq_theta(6, 0.4);
    int p = y * 3;                       /* hoisted TEMPLATE rail read as data */
    int s = 0;
    s += cq_measure((p >> 1) & 1); s += cq_measure((p >> 2) & 1);
    y = cq_theta(y, 0.9);                /* ⚠ THE ADDED LINE — post-loop Ry on y */
    return s + cq_measure(y);
}
int main(void) { return ka() + kb(); }
