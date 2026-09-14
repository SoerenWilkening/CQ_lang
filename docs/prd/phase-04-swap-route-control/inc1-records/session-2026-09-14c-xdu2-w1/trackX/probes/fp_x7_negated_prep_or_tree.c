#include "CQ.h"
/* F x P with the prep on the NEGATED arm (the `ry; ry_controlled(-t)`
   additivity spelling) AND a non-vacuous tree: b1|b0 has support on both
   |01> and |10>. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (!b0) { b1 = cq_theta(b1, 0.5); }
    if (b1 || b0) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1);
}
