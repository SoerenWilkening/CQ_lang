/* ADV-2 — a body rail with FAN-OUT 2 (the Rule-8 linear-lineage guard).  If the
   spine bails on the shared prefix the rolled form leaks it while the twin does
   not. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) {
        int t = y >> k;
        s += cq_measure(t & 1) + cq_measure(t & 2);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
