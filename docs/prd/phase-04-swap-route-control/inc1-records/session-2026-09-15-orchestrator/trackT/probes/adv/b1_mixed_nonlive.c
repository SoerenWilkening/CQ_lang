/* ADV-B1 — the (ii-c) BOUNDARY, pinned POSITIVELY and independently of the bd
   `s82e` fence: the same mixed shape as a3 but with NO post-loop rotation, so the
   fence's conjunct (2) is empty and the module ACCEPTS.  The accept must still
   emit NO `_unc` and NO `cqrt_free` — i.e. the loop is still UNMARKED, because
   `p = y * 3` is a hoisted TEMPLATE rail read as DATA and clause (ii-c) admits
   only MEASURE-OWNED ones.  If a `_unc` appears here, (ii-c) over-widened and the
   K-adjoints-against-one-forward-gate multiplicity miscompile is live. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int p = y * 3;
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure(y & 1) + cq_measure((p >> k) & 1);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
