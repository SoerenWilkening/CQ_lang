#include "CQ.h"
/* bd hn29 case (2) == bd leyd: two CONDITIONALLY prepped bools conjoined.
   The FIRST prep's merge phi lands OUTSIDE the kickback's own Pred (the second
   prep's diamond pushes it out).  Identical program to trackP/probes/p20.c and
   to trackX/probes/fp_x3_two_preps_two_phi_leaves.c. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    bool b2 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b0) { b2 = cq_theta(b2, 0.9); }
    if (b1 && b2) cq_phi(0.3);
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2);
}
