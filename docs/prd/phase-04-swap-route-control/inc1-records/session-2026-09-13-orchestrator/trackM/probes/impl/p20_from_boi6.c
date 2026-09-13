/* p20 — the 4.4 DATA select (1b-B.1's consumer) on a MERGE-PHI bool. */
#include "CQ.h"
int main(void) {
    int  q = cq_theta(5, 0.2);
    bool b = cq_theta((bool)0, 0.4);
    if (q > 3) b = cq_theta(b, 0.9);
    int a = b ? 2 : 5;
    return cq_measure(q) + cq_measure(b) + a;
}
