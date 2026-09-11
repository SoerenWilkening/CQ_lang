/* M1: the MINIMAL shape of the owner's second region -- bare rail cond + _Bool prep. */
#include "CQ.h"
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) b1 = cq_theta(b1, 0.5);
    return cq_measure(b0) + cq_measure(b1);
}
