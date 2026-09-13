/* r10 with the arms the other way round (rotation seen FIRST). */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a < 3) { b1 = !b1; } else { b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
