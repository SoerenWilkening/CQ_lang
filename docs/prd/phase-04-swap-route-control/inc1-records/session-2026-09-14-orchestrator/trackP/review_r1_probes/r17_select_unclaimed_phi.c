#include "CQ.h"
/* the 4.4 SELECT consumer's `control flow` decline, anchored at `Sel`.
   A loop-carried header phi as the select's condition: rung 0 fails. */
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int a = 0;
    for (int i = 0; i < 3; ++i) {
        a = b ? 2 : 5;
        b = !b;
    }
    return cq_measure(b) + cq_measure(a);
}
