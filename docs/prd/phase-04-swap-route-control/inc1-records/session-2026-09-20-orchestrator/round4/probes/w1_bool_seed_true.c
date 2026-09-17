/* w1 — the `i1` carried handle with a TRUE seed: the promotion emits
 * `cqrt_alloc_i1(i1 true)` and the runtime's `cqrt_alloc_i1(bool)` is a
 * `zeroext` parameter in C.  Checks both the width and the i1 ABI. */
#include "CQ.h"
int main(void) {
    bool acc = 1;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) acc = 0;
    }
    return (int)cq_measure(acc);
}
