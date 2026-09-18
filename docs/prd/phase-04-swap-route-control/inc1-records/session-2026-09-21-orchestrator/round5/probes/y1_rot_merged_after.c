// Y1 — d1 with ONE line added: a NON-DIAGONAL gate on the MERGED register `a`
// after the loop.  In every composed accept the value path leaves the PRE-MERGE
// rails (`cq_template_add_i32_hl` and the previous trips' `%out`) ALLOCATED and
// entangled with the b0 prep rails; `a`'s final value is a controlled copy of
// them, so they are a coherent which-path record OF `a`.  Rotating `a` is the
// interference Rule 8 says such a record dephases.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    a = cq_theta(a, 0.7);
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
