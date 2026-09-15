/* d5b — a bank load reaching a `cq_theta` arg-0.  `Chained` would read it as a
   SOURCE and re-prepare a live rail. */
#include "CQ.h"
int main(void) {
    bool b0[3];
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    bool x = cq_theta(b0[0], 0.25);
    return cq_measure(x);
}
