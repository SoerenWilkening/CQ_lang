/* F-5 probe e: E2's QUANTUM rival (DECISIONS E9) INSIDE a rail-bank module.
   `q + u` folds to undef, so a user-written QUANTUM measurement vanishes --
   does it also disturb the bank's three? */
#include "CQ.h"
int slice(void) {
    bool b0[3];
    int u;
    int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    int q = cq_theta(0, 0.3);
    s += cq_measure(q + u);
    return s;
}
int main(void) { (void) slice(); return 0; }
