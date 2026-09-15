/* Track T — bd `tu9q`, THE L1 PROBE. A loop granted the round-1 root-mint
   marking on `y`, whose body ALSO reads a value that is CLASSICAL at round-1
   taint and TAINTED after `repropagateControlMerges` re-seeds from the 4.4
   merge `%out` rail.  `lowerLoops` runs BEFORE `detectControlRegions`, so at the
   grant the merge phi `a` is an untainted i32; after the fixpoint it is a
   `cqrt_alloc_i32`-minted tainted rail read inside `L` and NOT on `Roots`, i.e.
   exactly the "accumulating loop-invariant tainted input" clause the grant was
   asked under and passed.  `declineRound2FalsifiedRailGrants` must catch it. */
#include "CQ.h"
int slice(void) {
    int q = cq_theta(5, 0.5);
    int y = cq_theta(7, 0.3);
    int a;
    if (q & 1) a = 2; else a = 5;
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure((y >> k) & a);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y) + cq_measure(q);
}
int main(void) { return slice(); }
