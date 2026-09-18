// Z4 — Z3's CONTROL: the same body with a STATIC trip bound, so there is no guard
// and no zero-trip path.  If Z4 is clean and Z3 is not, the guard is the cause.
#include "CQ.h"
int slice(int u) {
    int y = cq_theta(7, 0.3);
    int q = cq_theta(u, 0.5);
    int m2 = q * 2;
    int acc = 0;
    for (int k = 1; k < 3; k++) {
        acc += cq_measure((y >> k) & m2);
    }
    q = cq_theta(q, 0.9);
    return acc + cq_measure(q) + cq_measure(y);
}
int main(void) { return slice(4); }
