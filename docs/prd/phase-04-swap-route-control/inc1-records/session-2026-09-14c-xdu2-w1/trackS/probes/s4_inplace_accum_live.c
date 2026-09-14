/* Track S — THE IN-PLACE ACCUMULATOR NEGATIVE (coordinator's binding point 2:
   "must NOT fire on superseded value rails").  A loop-CARRIED register updated
   IN PLACE in the body (`tryCaseA`'s dtzb accumulator, which lowers to
   `cqrt_addc_i32` and mints NO new rail), with a post-loop rotation on it.  The
   body is UNMARKED — `tryCaseA` claimed the loop, so `markIfIterationLocal` is
   never called — so conjunct (1) is satisfied and only the in-place exclusion
   can keep this accepting.  ⚠ The first spelling of this probe (`a -= 3` with a
   constant) was WORTHLESS: -O1 folded the whole loop to `a - 6` and LI.empty()
   made the stage never run.  The `+ k` keeps the loop alive. */
#include "CQ.h"
int slice(void) {
    int a = cq_theta(7, 0.25);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        a = a + k;
        s += cq_measure(a & 1);
    }
    a = cq_theta(a, 0.9);
    return s + cq_measure(a);
}
int main(void) { return slice(); }
