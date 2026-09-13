/* m15u — the RAIL-LEAF spelling of m15: m17 (unconditional b1 prep, so the
   select's condition is a bare cq_theta_i1 CALL) PLUS the second prep after the
   select. If the ORACLE accepts this, m15's accept on the subject is the
   PRE-EXISTING r9e5 disposition reached through a new spelling, not a new
   over-accept. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    b1 = cq_theta(b1, 0.5);
    if (b1) a -= 3;
    b1 = cq_theta(b1, 0.25);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
