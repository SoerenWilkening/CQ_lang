/* b07 — a BANK with an UNCONDITIONAL per-trip prep: no control region at all
   inside the loop. The floor of the bank capability. */
#include "CQ.h"
int main(void) {
    bool b0[3];
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]);
}
