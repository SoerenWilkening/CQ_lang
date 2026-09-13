/* H-9 control: cq_invert around a region the ORACLE already accepts (m17's
   rail-leaf select), to show the accept-then-LINKFAIL state is PRE-EXISTING
   Phase-8 and not created by Track M. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    b1 = cq_theta(b1, 0.5);
    cq_invert_begin();
    if (b1) a -= 3;
    cq_invert_end();
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
