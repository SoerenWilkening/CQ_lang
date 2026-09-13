/* item 3, second half — the filed 3qps leaf-grammar decline: the THIRD region
   is a PHASE kickback on the same merge phi. */
#include "CQ.h"
#include <math.h>
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;
    if (b1) { cq_phi(0.3); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
