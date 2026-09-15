/* RE-ATTACK 6 (Rule 13) — SIBLING loops, not nested.  `L1` is fully
   iteration-local (marked); `L2` mints a which-path rail of the interfered
   register.  `L1`'s blocks are in NEITHER `L2->blocks()` NOR `L2`'s own blocks,
   so neither the old conjunct (1) nor the new one can be silenced by it — the
   control that says the defect really was about CONTAINMENT and not about
   "some marked block exists in this function". */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 0; i < 2; ++i) { int u = cq_theta(6, 0.4); s += cq_measure((u >> i) & 1); }
    for (int k = 1; k <= 2; ++k) s += cq_measure((y >> k) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
