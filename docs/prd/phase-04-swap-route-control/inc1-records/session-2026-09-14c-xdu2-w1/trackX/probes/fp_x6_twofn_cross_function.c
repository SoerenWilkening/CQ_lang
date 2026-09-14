#include "CQ.h"
/* bd 1yeu — every corpus and gate in the tree is ONE FUNCTION PER MODULE.  Two
   F x P customers in ONE module: does either function's lowering change? */
int f_phase(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1 && b0) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1);
}
int f_or(void) {
    bool c0 = cq_theta((bool)0, 0.5);
    bool c1 = 0;
    if (c0) { c1 = cq_theta(c1, 0.5); }
    if (c1 || c0) cq_phi(0.7);
    return cq_measure(c0) + cq_measure(c1);
}
int main(void) { return f_phase() + f_or(); }
