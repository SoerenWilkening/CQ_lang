/* Track beta P5 — soundness of `railIsInterior`'s MEASURE-OWNED exclusion.
   The only in-body tainted BinaryOperator is an `lshr` whose SOLE user is a
   `cq_measure`, so conjunct (3) skips it. Does it in fact NOT diverge? */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure(y >> k);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
