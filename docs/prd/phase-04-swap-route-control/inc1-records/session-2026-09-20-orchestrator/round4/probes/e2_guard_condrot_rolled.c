/* e2 rolled — the guarded loop, trailing non-diagonal gate on a register the
 * CONDITION reads (a loop-carried bool bank), not on the accumulator. */
#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int n = argc;
    int acc = 5;
    bool b0[4];
    for (int i = 0; i < n && i < 4; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) acc = 1;
    }
    b0[0] = cq_theta(b0[0], 0.9);   /* TRAILING NON-DIAGONAL GATE on a CONDITION register */
    return cq_measure(acc) + cq_measure(b0[0]);
}
