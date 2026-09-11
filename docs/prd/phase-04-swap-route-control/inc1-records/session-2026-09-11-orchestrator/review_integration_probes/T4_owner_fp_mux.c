/* the peeled mux is an fp DATA select (kjd1) beside the bool prep */
#include "CQ.h"
int main(void) {
    double a = 5.0; bool b0 = 0; bool b1 = 0;
    if (a >= 3.0){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3.0;
    if (a >= 3.0){ b1 = cq_theta(b1, 0.5); }
    return cq_measure(b0)+cq_measure(b1)+(int)cq_measure(a);
}
