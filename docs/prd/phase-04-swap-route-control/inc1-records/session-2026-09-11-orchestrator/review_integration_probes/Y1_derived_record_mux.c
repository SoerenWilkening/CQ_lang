/* the peeled mux copies a rail DERIVED from the register the prep arm rotates in place */
#include "CQ.h"
int main(void) {
    bool b1 = cq_theta((bool)0, 0.2);
    bool b0 = cq_theta((bool)0, 0.5);
    int d = (int)b1 * 2;
    int a;
    if (b0) { a = d; } else { b1 = cq_theta(b1, 0.5); a = 9; }
    return cq_measure(a) + cq_measure(b1) + cq_measure(b0);
}
