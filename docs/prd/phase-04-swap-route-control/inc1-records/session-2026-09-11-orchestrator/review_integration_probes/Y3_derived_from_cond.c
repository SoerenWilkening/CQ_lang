/* the peeled mux copies a rail derived from the CONDITION register */
#include "CQ.h"
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    int d = (int)b0 * 2;
    int a; bool b1 = 0;
    if (b0) { a = d; b1 = cq_theta(b1, 0.5); } else { a = 9; }
    return cq_measure(a) + cq_measure(b1) + cq_measure(b0);
}
