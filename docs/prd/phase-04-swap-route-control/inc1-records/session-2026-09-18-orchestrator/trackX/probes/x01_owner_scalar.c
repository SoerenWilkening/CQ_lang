/* x01_owner_scalar.c — Track X (bd x5fp), session 2026-09-18.
   The reference reproduction: trackL/probes/s_loop_n2.c verbatim, re-measured on
   THIS session's ORACLE (cq-opt 9bd01598…). S-1, the §3c clobber fence, through
   the BACK EDGE. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b = 0;
    for (int i = 0; i < 2; ++i) {
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) a -= 3;
    }
    return cq_measure(a) + cq_measure(b);
}
