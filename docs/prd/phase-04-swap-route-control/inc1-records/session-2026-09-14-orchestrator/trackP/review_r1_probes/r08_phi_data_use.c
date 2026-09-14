#include "CQ.h"
/* The "condition used outside the branch" fence (step 6, IsTree) builds TreeSet
   from Tree.Leaves + Tree.Nodes ONLY -- neither RailLeaves nor RailPhiLeaves.
   That site is NOT in IMPL_P §3's 23-row table.  Probe: the phi leaf has a DATA
   use outside the branch as well as being the condition. */
int main(void) {
    int q = cq_theta(0, 0.7);
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1 && q > 3) cq_phi(0.3);
    int z = (int)b1 + q;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(z);
}
