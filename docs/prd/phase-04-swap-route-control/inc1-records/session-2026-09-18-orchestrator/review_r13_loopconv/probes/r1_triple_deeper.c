/* SUBJECT (B) ATTACK — the emkg conjunct-(1) shape ONE LEVEL DEEPER STILL:
   FOUR levels, the rail on the level-2 loop, the marked loop at level 4.
   `r1_triple_nest_mid_rail` is the 3-level pinned decline; this asks whether the
   own-blocks filter still sees the rail when two marked loops sit below it. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int h = 0; h < 2; ++h)
      for (int i = 0; i < 2; ++i)
        for (int j = 1; j <= 2; ++j) {
            s += cq_measure((y >> j) & 1);
            for (int k = 0; k < 2; ++k) {
                int u = cq_theta(6, 0.4);
                s += cq_measure((u >> k) & 1);
            }
        }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
