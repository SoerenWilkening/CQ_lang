#include "CQ.h"
/* Track M's pinned F-M3: the IN-PLACE-ARM phi (a phi consumed as the condition
   of a SECOND in-place rotation arm).  Must still decline; bd 3d8q names its
   retirement. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    bool b2 = cq_theta((bool)0, 0.7);
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1) { b2 = cq_theta(b2, 0.9); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2);
}
