/* h1: L1 -- the loop's EXIT CONDITION is data-untainted at ROUND-1 taint (a 4.4
   value merge over two CLASSICAL CONSTANTS is data-untainted; only its condition
   is tainted) and TAINTED after `repropagateControlMerges` re-seeds from the
   merge `%out`.  (Z7) `taintedExit` -- and `tryCaseA`'s own Q1 -- are asked at
   ROUND-1 taint only.  If this compiles, the emitted circuit's TRIP COUNT is
   quantum-dependent, which Rule 18 makes a permanent decline. */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    bool c = cq_theta((bool)0, 0.5);
    int n = 2;
    if (c) n = 3;
    for (int i = 0; i < n; ++i) {
        bool b = cq_theta((bool)0, 0.25);
        if (b) a -= 3;
    }
    return cq_measure(a);
}
int main(void) { (void) run(); return 0; }
