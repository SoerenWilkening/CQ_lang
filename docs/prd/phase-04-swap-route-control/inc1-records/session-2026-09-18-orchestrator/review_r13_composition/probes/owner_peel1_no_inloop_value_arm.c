// ITEM 7 — the owner's LOOP program with ONE wall hand-peeled.
// WALL 1 on the COMBINED binary is `cq controlled lowering: control flow inside a
// loop body under quantum control` at grover_oracle_uncompute.c:91:15 — the
// `if (a >= 3)` state-prep region, which is quantum-controlled only because
// `if (b0[i]) a -= 3;` makes `a` tainted and loop-carried. Peel = delete that one
// line; everything else is character-for-character the owner's.
#include "CQ.h"
#include <math.h>
int main(void) {
    int a = 5;
    bool b0[3];

    for (int i = 0; i < 3; ++i) {
        if (a >= 3){
            b0[i] = cq_theta(b0[i], 0.5);
        }
    }
    return cq_measure(b0[0]) + cq_measure(b0[1])  + cq_measure(b0[2]) + cq_measure(a);
}
