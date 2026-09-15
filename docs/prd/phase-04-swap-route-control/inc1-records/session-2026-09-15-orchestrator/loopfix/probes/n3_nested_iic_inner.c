/* R13-r2 N3 — THE COMPOSITION INSTANCE: the inner loop is marked ONLY by Track T
   (clause (ii-c) on the hoisted measure-owned `y & 1`), and that marking silences
   Track S′'s widened fence for the OUTER loop, whose own body rail diverges. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 1; i <= 2; ++i) {
        s += cq_measure((y >> i) & 1);
        for (int j = 0; j < 2; ++j) {
            int u = cq_theta(6, 0.4);
            s += cq_measure((u >> j) & 1) + cq_measure(y & 1);
        }
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
