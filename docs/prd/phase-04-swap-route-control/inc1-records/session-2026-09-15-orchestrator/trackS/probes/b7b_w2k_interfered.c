/* Track beta P7b — THE BENIGN HALF ATTACKED PROPERLY.  This is bd `s82e`'s own
   exhibit `w2k_noregion_invread` (ruled BENIGN by D4 and pinned as an ACCEPT by
   `loop_leak_dephase_accept_pertrip_dead.ll`) with ONE line added: the per-trip
   register `u` is re-rotated before the trip ends.  The invariant read of `y`
   still leaves the body UNMARKED, so the per-trip rails still leak. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1) + cq_measure(y & 1);
        u = cq_theta(u, 0.9);      /* the interference, INSIDE the loop */
        s += cq_measure(u);
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
