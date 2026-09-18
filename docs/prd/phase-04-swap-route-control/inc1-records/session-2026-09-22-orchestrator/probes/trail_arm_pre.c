/* Its PRE-HOISTED twin: the same circuit with the cone forced into the pred by
 * an extra classical use, so -O1 cannot sink it into the arm. */
#include "CQ.h"
int k;
int sink;
static int slice(void) {
    int q = 0; q = cq_theta(q, 0.5);
    int p = 0; p = cq_theta(p, 0.25);
    int t = (k*3 + 7) ^ 5;
    sink = t;
    if (q > 5) { p += t; }
    p = cq_theta(p, 0.9);
    return cq_measure(p) + cq_measure(q);
}
int main(void) { (void)slice(); return 0; }
