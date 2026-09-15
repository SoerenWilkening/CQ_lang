/* d5k — the bank's stored value is a COMPARE, not a theta result: the storage
   `zext i1 -> i8` sits in front of a `cq_template_icmp_*` rail the type rewrite
   has not seen yet (`lowerOps` runs AFTER it). */
#include "CQ.h"
int main(void) {
    bool b0[3]; int s = 0; int q = cq_theta(q, 0.5);
    for (int i = 0; i < 3; ++i) b0[i] = (q > 3);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
