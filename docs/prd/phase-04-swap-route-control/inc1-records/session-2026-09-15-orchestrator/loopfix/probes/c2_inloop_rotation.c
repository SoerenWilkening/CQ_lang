/* The program of `loop_leak_dephase_reject_inloop_rotation.ll` (bd
   `test_C_libtooling-c767`) — bd `s82e`'s exhibit `w2k_noregion_invread` with
   one line added.  Same L8 retirement trigger, same re-derivation. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1) + cq_measure(y & 1);
        u = cq_theta(u, 0.9);
        s += cq_measure(u);
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
