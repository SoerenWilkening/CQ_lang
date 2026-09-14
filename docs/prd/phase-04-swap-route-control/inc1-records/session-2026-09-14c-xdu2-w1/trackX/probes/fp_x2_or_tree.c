#include "CQ.h"
/* F x P with an OR tree instead of AND over the same two rail leaves. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1 || b0) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1);
}
