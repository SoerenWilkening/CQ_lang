/* the prep SEED is 1, not 0: the merge phi's pred incoming is `true`.
   M-beta RAUWs the phi to the hoisted theta whose arg-0 is `i1 true`; the
   select's control is then the prepped rail. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 1;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
