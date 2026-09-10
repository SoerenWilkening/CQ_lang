/* p04 — the KICKBACK twin of p03: the same borrowed chain with a register-free
   `cq_phi` region instead of the data select. Clause (1) admits the
   `cqrt_rz_i1` on the borrowed parent, so this one should discharge. */
#include "CQ.h"
int main(void) {
    _Bool b = cq_theta(0, 0.25);
    int d = (int) b + 3;
    if (b) cq_phi(0.7);
    return cq_measure(d);
}
