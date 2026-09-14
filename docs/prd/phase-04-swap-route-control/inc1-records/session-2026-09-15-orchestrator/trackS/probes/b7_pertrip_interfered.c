/* Track beta P7 — ATTACK ON THE BENIGN HALF (my brief item 3; Track S IMPL_S
   §16.5, which flagged it and did not build it).  `w2k`'s shape, but the
   PER-TRIP register `u` is INTERFERED (re-rotated) before the trip ends and is
   then MEASURED.  D4's benign argument is "their joint garbage never reaches
   the retained subsystem" — here it reaches the program's own observable. */
#include "CQ.h"
int slice(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1);
        u = cq_theta(u, 0.9);      /* the interference, INSIDE the loop */
        s += cq_measure(u);
    }
    return s;
}
int main(void) { return slice(); }
