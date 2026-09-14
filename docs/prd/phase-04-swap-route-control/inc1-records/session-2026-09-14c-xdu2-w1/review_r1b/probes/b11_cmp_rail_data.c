/* Track beta P11 — conjunct (3) scans `BinaryOperator` ONLY (IMPL_S §16.1).
   Here the body's ONLY rail-minting interior op is an `icmp` used as DATA, not
   as a region flag: icmp -> zext -> cq_measure.  There is no BinaryOperator in
   the body at all. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure(y > k);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
