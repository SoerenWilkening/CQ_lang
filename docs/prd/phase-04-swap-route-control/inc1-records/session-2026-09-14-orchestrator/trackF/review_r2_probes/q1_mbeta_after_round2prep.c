/* Q1 — the §R2 construction, plain C.
   Region C (round 1, 4.4 value)  : `if (b0) a -= 3;`   -> `a` becomes an out-rail
   Region B (round 2, state prep) : `if (a >= 3) b1 = cq_theta(b1,.5);`  -> M_B
   Region A (round 1, in-place Ry): `if (b0) b1 = cq_theta(b1,.25);`     -> M-beta RAUW,
                                     whose theta BASE is M_B.
   The drift F-F1-5 names would put every former user of M_A into PhiDesc_B in round 2. */
#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int a = argc + 4;
    bool b0 = 0, b1 = 0;
    b0 = cq_theta(b0, 0.5);
    if (b0) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    if (b0) { b1 = cq_theta(b1, 0.25); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
