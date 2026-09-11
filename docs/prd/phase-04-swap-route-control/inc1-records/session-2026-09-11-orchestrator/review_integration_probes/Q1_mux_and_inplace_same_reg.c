/* one fused diamond: an in-place-Ry arm on r AND a peeled mux over r's pre-value */
#include "CQ.h"
int main(void) {
    bool r = cq_theta((bool)0, 0.2);
    bool c = cq_theta((bool)0, 0.5);
    int pre = (int)r;
    int a; int e;
    if (c) { a = 2; e = pre; } else { r = cq_theta(r, 0.5); a = 5; e = 0; }
    return cq_measure(a)+cq_measure(e)+cq_measure(r)+cq_measure(c);
}
