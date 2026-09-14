/* R2-I4 — can the ORACLE reach the anchorless `condition predates a non-diagonal
   gate` decline at all?  A FLAT onward-phase module over a 6.5 `%out`. */
#include "CQ.h"
int ext_f(int a);
int slice(void) {
    int q = cq_theta(3, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    if (y > 50) cq_phi(0.3);
    int r = cq_theta(y, 0.2);
    return cq_measure(r) + cq_measure(q);
}
int main(void) { return slice(); }
