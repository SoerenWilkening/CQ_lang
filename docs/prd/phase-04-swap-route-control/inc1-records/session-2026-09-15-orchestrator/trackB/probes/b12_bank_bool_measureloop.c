/* b12 — SCOPE_L1a §1's canonical customer shape: bool bank, measures in a
   second loop. */
#include "CQ.h"
int main(void) {
    bool b0[3]; int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
