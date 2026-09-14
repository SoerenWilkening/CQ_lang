/* R2-L — the exclusion must NOT rescue a loop that has a real candidate beside
   the in-place op: a dtzb in-place `q += 3` PLUS a per-trip derived chain, in a
   body whose marking is refused by the loop-invariant read of `b`. */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  q = cq_theta(5, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        if (b) r = cq_theta(r, 0.3);
        q = q + 3;
        s += cq_measure(q) + cq_measure((u >> 1) & 1) + cq_measure((int)b & 1);
    }
    return s + cq_measure(r);
}
int main(void) { return slice(); }
