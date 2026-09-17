/* t32 rolled — the `int` WIDTH CONTROL for t16: identical program at i32, which
 * lowered on the ORACLE too.  Its trace is what t16's must be, symbol-for-symbol,
 * with every `_i32` replaced by `_i16`. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    return (int)cq_measure(a);
}
