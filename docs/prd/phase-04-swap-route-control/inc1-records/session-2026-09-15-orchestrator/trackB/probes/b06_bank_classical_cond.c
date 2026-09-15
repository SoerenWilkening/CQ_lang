/* b06 — a BANK with a CLASSICAL loop condition and all measures after the loop.
   The minimal program W1's second half alone must make compile (no tainted
   accumulator, so no X1 and no (c3) escape). */
#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int a = argc;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
    }
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]);
}
