/* W5 — THE decision-relevant measurement for a DOMINANCE-based exclusion: the
   program `control_inplace_ry_reject_stateprep_second_flag_i1.ll` says it is
   `-O1`'s image of.  Does `clang -O1` (a) substitute `true` for the off-wire
   flag in the arm AND (b) SINK the flag's compare below the branch?  If both,
   a dominance fence would over-accept that fixture's class. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(0, 0.5);
    bool d = (q > 7);
    bool r = 1;
    if (q > 100) { r = cq_theta(d, 0.9); }
    return cq_measure(q) + cq_measure(d) + cq_measure(r);
}
