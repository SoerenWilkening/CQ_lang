#include "CQ.h"
/* cq-zzpg (CR rules 2, 20; cq-bfz4 sharing): x sits in q[*] and p[*] (shared, nothing writes it in place
   yet). r[i] = q[j] moves q's rail into r (q is dead after), but p still holds the same rail: the in-place
   Ry on r[k] must act on a rail no other live holder names, so r's cell takes a basis copy. */
int share_moved_ry(unsigned i, unsigned j, unsigned k) {
    int q[2], p[2], r[2];
    int x = 0;
    cq_theta(&x, 1.0);
    q[0] = x; q[1] = x; p[0] = x; p[1] = x;
    r[i & 1] = q[j & 1];
    r[(i & 1) ^ 1] = 0;
    cq_theta(&r[k & 1], 0.7);
    return cq_measure(r[k & 1]) + 2 * cq_measure(p[k & 1]);
}
