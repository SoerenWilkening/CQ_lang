#include "CQ.h"
/* CONTROL for p20: the same conjunction over two UNCONDITIONALLY prepped bools
   is two plain RAIL leaves (no phi at all) and has lowered since bd 3qlq.4. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = cq_theta((bool)0, 0.9);
    if (b0 && b1) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1);
}
