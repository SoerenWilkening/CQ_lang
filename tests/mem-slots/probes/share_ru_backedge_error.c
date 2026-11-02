#include "CQ.h"
/* cq-zgw3 (CR rules 6, 20; cq-bfz4 sharing): the register update q[k] ^= q[k + 1] is lowered (with its rule 6
   clean) before the store p[r] = q[0], which leaves q[0]'s rail in a second cell, and the outer loop runs the
   update again after that store: it would free the rail p[0] holds (main: use after free), or orphan a basis
   copy of it. Keeping the rail there (rule 6 Dead) is not built: an internal error. */
int share_ru_backedge(unsigned n, unsigned j) {
    int q[4], p[2];
    int x = 0;
    cq_theta(&x, 1.0);
    j &= 1; n &= 3;
    q[0] = x; q[1] = 0; q[2] = 1; q[3] = 0;
    for (unsigned r = 0; r < 2; r++) {
        for (unsigned k = 0; k < n; k++) q[k] ^= q[k + 1];
        p[r] = q[0];
    }
    return cq_measure(q[0]) + 2 * cq_measure(p[j]);
}
