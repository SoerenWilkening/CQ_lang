/* g1: TARGET 1 / (P1) abuse. `BreakReversePlay` puts the break construct's
   R/idx/OUT scratch into `taint.ControlOwnedRails` (LoopLowering.cpp:2119),
   minted in the INNER loop's preheader -- which is INSIDE the OUTER loop.  The
   break's escape phi is RAUW'd to `OutReg`, so an OUTER carried variable taking
   the inner loop's escape value has `OutReg` as its latch incoming: in
   `ControlOwnedRails` and inside the outer loop, i.e. (P1) grants on a rail that
   is NOT a controlled-copy merge `%out`. */
#include "CQ.h"
__attribute__((noinline))
int run(int seed) {
    int a = 5;
    for (int j = 0; j < 2; ++j) {
        int q = cq_theta(seed, 0.25);
        for (int i = 0; i < 4; ++i) {
            q = q ^ 5;
            if (q == 7) break;
        }
        a = q;
    }
    return cq_measure(a);
}
int main(void) { (void) run(3); return 0; }
