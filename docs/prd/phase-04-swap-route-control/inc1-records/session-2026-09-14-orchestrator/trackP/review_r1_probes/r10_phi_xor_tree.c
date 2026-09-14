#include "CQ.h"
/* the xor NODE (bd 3c6m.67) with a phi LEAF: a grammar composition nobody
   probed.  b1 is a prep phi, b0 a plain rail. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1 != b0) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1);
}
