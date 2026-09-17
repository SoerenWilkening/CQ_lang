/* x03_no_clobber_control.c — Track X (bd x5fp), session 2026-09-18.
   THE ISOLATING CONTROL for x02: identical, minus the back edge. `a` no longer
   depends on the measure, so condProvenance never reaches %r and §3c cannot
   fire. Whatever this probe declines on is a wall that x02 ALSO has, i.e. a
   wall BEHIND S-1 — which is exactly what the witness question asks. */
#include "CQ.h"
int main(void) {
    int a = 0;
    int t = 0;
    for (int i = 0; i < 3; ++i) {
        int q = cq_theta(9, 0.3);
        int r = cq_theta(7, 0.2);
        if (q >= a) r = r + 3;        /* VALUE arm on r; NO back-edge link */
        t += cq_measure(r);
    }
    return t;
}
