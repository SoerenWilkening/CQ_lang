/* ADV-9 — a quantum SUBLOOP inside the marked body: its gates run N times per
   outer trip while a single in-body reversal would adjoint them once.  Both
   markers must refuse. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        for (int j = 0; j < 2; ++j)
            s += cq_measure((y >> (k + j)) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
