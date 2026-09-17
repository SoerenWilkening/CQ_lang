/* SUBJECT (C) — t5d WITHOUT the post-loop rotation, so bd 3d8q cannot preempt.
   A MULTI-BLOCK break body with a CLASSICAL break: does the discharge land, and
   is it right on the break path? */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        s += cq_measure((y >> k) & 1);
        if (k >= lim) break;
        s += cq_measure((y >> (k + 8)) & 1);
        s += cq_measure((y >> (k + 16)) & 1);
    }
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
