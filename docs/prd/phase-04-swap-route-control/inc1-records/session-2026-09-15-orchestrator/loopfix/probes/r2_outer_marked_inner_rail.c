/* RE-ATTACK 3 (Rule 13) — THE OPPOSITE NESTING: the OUTER loop is fully
   iteration-local (so `markIfIterationLocal` marks all of `L_outer->blocks()`,
   INCLUDING the subloop's), while the INNER loop mints a which-path rail of a
   register that is rotated afterwards.  Asks whether `bodyBlocksMarked` silences
   the fence for the INNER loop on a marking that covers it — and whether that is
   sound (it is: a marked block means the spine discharges IN that block, i.e.
   per INNER trip). */
#include "CQ.h"
int slice(void) {
    int s = 0;
    for (int i = 0; i < 2; ++i) {
        int w = cq_theta(7, 0.3);
        for (int j = 1; j <= 2; ++j)
            s += cq_measure((w >> j) & 1);
        w = cq_theta(w, 0.9);
        s += cq_measure(w);
    }
    return s;
}
int main(void) { return slice(); }
