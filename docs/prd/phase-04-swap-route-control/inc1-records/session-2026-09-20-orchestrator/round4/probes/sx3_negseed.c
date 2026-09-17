/* sx3 — t16_rolled with a NEGATIVE seed.  The promotion emits
 * `cqrt_alloc_i16(i16 -3)` with no `signext`; the runtime prints what it reads. */
#include "CQ.h"
int main(void) {
    short a = -3;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    return (int)cq_measure(a);
}
