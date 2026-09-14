/* w_grover_bool — "Grover as a ROLLED loop with a _Bool-controlled rotation",
   the sentence CLAUDE.md records as compiling in NO spelling on ANY binary. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(7, 0.25);
    for (int k = 0; k < CQ_K; ++k) {
        if (b) r = cq_theta(r, 0.9);
        r = cq_theta(r, -0.5);
        r = cq_theta(r, 0.5);
    }
    return cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
