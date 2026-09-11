/* depth-2 nest whose inner merge carries a peelable phi beside a prep */
#include "CQ.h"
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool c  = cq_theta((bool)0, 0.7);
    int a = 5; bool b1 = 0;
    if (b0) { if (c) { a = 2; b1 = cq_theta(b1, 0.5); } }
    return cq_measure(b0)+cq_measure(c)+cq_measure(b1)+cq_measure(a);
}
