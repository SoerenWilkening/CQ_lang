/* the merge phi feeds BOTH the select and a tainted arithmetic consumer
   (M-beta RAUWs every use of the phi, not just the select's). */
#include "CQ.h"
int main(void) {
    volatile int av = 5;
    int a = av; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;
    int d = a + (int)b1;          /* b1 read as DATA as well as as a control */
    return cq_measure(b0) + cq_measure(b1) + cq_measure(d);
}
