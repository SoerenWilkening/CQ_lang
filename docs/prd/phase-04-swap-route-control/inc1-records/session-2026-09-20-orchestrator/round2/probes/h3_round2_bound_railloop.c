/* h3: L1, the sharper spelling.  The loop BOUND `n` is the merge of two CLASSICAL
   CONSTANTS under a tainted condition -- data-untainted at ROUND-1 taint, tainted
   after `repropagateControlMerges`.  The body is a plain 7.3 in-place value rail,
   so nothing in it needs round-2 control detection.  `taintedExit` (Q1, and
   `loopCarriedHandlePhi`'s (Z7)) is asked at ROUND-1 taint only.  If this
   compiles, the emitted circuit's TRIP COUNT is quantum-dependent. */
#include "CQ.h"
__attribute__((noinline))
int run(int seed) {
    bool c = cq_theta((bool)0, 0.5);
    int n = 2;
    if (c) n = 3;
    int q = cq_theta(seed, 0.25);
    for (int i = 0; i < n; ++i)
        q = q ^ 5;
    return cq_measure(q) + cq_measure(c);
}
int main(void) { (void) run(3); return 0; }
