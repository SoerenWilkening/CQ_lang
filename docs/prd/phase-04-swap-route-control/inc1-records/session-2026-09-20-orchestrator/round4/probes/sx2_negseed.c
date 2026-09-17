/* sx2 — a NEGATIVE seed on the narrow carried handle.  The promotion's own new
 * emission is `materializeCopySource(seed, allocFn("i16"))` =
 * `call i32 @cqrt_alloc_i16(i16 -3)`, declared by `WidthDispatch::allocFn` with
 * NO `signext`.  The runtime's `cqrt_alloc_i16(int16_t value)` is compiled from C
 * and reads the full parameter register. */
#include "CQ.h"
int main(void) {
    short a = -3;
    bool b0[2];
    for (int i = 0; i < 2; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 1;
    }
    return (int)cq_measure(a);
}
