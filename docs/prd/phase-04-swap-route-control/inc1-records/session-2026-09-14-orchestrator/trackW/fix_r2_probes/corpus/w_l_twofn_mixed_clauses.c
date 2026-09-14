/* w_l — TWO FUNCTIONS, TWO DIFFERENT GRANT CLAUSES, BOTH ACCEPTING. The
   positive control for the per-function `LoopInfo` scoping (F-W1-1) and for the
   record-at-every-grant widening (F-W1-2): `f_c` is granted by clause (c) (every
   register iteration-local), `f_b` by clause (b') (the rotated register is
   loop-CARRIED), and both must keep lowering. */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 2
#endif
int f_c(void) {
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        bool t = cq_theta((bool)0, 0.5);
        int r = cq_theta(7, 0.25);
        if (t) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(t);
    }
    return s;
}
int f_b(void) {
    int r = cq_theta(7, 0.25);
    bool b = cq_theta((bool)0, 0.5);
    for (int k = 0; k < CQ_K; ++k) { if (b) r = cq_theta(r, 0.2); }
    return cq_measure(r) + cq_measure(b);
}
int main(void) { return f_c() + f_b(); }
