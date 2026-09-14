/* R2-C' — the same, plus a NON-control read of the loop-invariant rail `b` in
   the body, spelled so the reading instruction is ITSELF one of the five
   excluded kinds (`cq_measure`).  That is the d3 route to `markIfRailLocal`'s
   "accumulating loop-invariant tainted input" refusal, reached WITHOUT giving
   `bodyHasSpineDischargeCandidate` a candidate to see. */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  q = cq_theta(5, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        if (b) r = cq_theta(r, 0.3);
        q = q + 3;
        s += cq_measure(q) + cq_measure(b);
    }
    return s + cq_measure(r);
}
int main(void) { return slice(); }
