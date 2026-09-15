/* d5f — the SCALAR control for d5e: one register, measured twice, NO array and
   NO bank anywhere.  If this compiles too, the double measurement is bd `yiid`'s
   pre-existing boundary and not something the rail bank creates. */
#include "CQ.h"
int main(void) {
    bool q = cq_theta(q, 0.5);
    return (int) cq_measure(q) + (int) cq_measure(q);
}
