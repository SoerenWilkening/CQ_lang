#include "CQ.h"
/* F x P x W — the THREE-WAY composition the merge gate did not construct: the
   prep merge-phi tree leaf INSIDE a classically-bounded loop (bd wx8g's
   territory). */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    for (int k = 0; k < 3; ++k) {
        if (b1 && b0) cq_phi(0.3);
    }
    return cq_measure(b0) + cq_measure(b1);
}
