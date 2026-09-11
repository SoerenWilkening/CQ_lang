/* two DIFFERENT rails read by one fused diamond's condition tree */
#include "CQ.h"
int main(void) {
    bool p = cq_theta((bool)0, 0.3);
    bool q = cq_theta((bool)0, 0.7);
    int a = 5; bool b1 = 0;
    if (p && q) a -= 3;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    return cq_measure(p)+cq_measure(q)+cq_measure(b1)+cq_measure(a);
}
