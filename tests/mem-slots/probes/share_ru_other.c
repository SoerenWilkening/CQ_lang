#include "CQ.h"
/* cq-zgw3 (CR rules 6, 20; cq-bfz4 sharing): x sits in q[0] and in p[*] (one shared rail). The register update
   q[k] ^= q[k + 1] supersedes q[0]'s rail at k = 0, but p still holds it and reads it afterwards: it is not
   dead (rule 6), so the update must not clean and free it. */
int share_ru_other(unsigned n, unsigned j) {
    bool q[4], p[2];
    bool x = 0;
    cq_theta(&x, 1.0);
    j &= 1; n &= 3;
    q[0] = x; q[1] = 0; q[2] = 1; q[3] = 0;
    p[0] = x; p[1] = x;
    for (unsigned k = 0; k < n; k++) q[k] ^= q[k + 1];
    return cq_measure(q[0]) + 2 * cq_measure(p[j]);
}
