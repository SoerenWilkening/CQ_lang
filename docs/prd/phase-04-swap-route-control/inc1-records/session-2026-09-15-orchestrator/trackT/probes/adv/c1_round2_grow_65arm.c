/* ADV-C1 — THE L1 REACHABILITY PROBE for `declineRound2FalsifiedRailGrants`.
   A 6.5 classical-call arm OUTSIDE the loop whose merged result is read INSIDE
   it.  At `lowerLoops` (round-1 taint, before `detectControlRegions`) the merge
   phi's incomings are a classical call result and a constant, so the phi is
   UNTAINTED and the loop is granted the root-mint marking on `y`.  After
   `repropagateControlMerges` re-seeds taint from the emitter's `%out` rail the
   body reads an accumulating loop-invariant TAINTED input that is not on `Roots`
   — the clause the grant was asked under and passed. */
#include "CQ.h"
__attribute__((const)) int helper(int x);
int slice(void) {
    int q = cq_theta(5, 0.5);
    int y = cq_theta(7, 0.3);
    int a = 3;
    if (q & 1) a = helper(4);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure((y >> k) & a);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y) + cq_measure(q);
}
int main(void) { return slice(); }
