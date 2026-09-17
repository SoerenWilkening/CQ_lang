// ITEM 7, the FAITHFUL peel. WALL 1 on the COMBINED binary is
//   grover_oracle_uncompute.c:91:15  cq controlled lowering: control flow inside
//   a loop body under quantum control
// and :91 is `if (a >= 3){`. Peel exactly that region — make the state prep
// unconditional — and keep everything else, INCLUDING `if (b0[i]) a -= 3;`.
// Whatever declines now is WALL 2 of the owner's loop program.
#include "CQ.h"
#include <math.h>
int main(void) {
    int a = 5;
    bool b0[3];

    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);      /* peeled: the `if (a >= 3)` guard */
        if (b0[i]) a -= 3;
    }
    return cq_measure(b0[0]) + cq_measure(b0[1])  + cq_measure(b0[2]) + cq_measure(a);
}
