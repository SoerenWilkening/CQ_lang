/* FLAT, one trip, trailing non-diagonal gate on the condition's register.
 * This is the shape the increment actually admits. */
#include "CQ.h"
int k;
static int slice(void) {
    int q = 0; q = cq_theta(q, 0.5);
    int p = 0; p = cq_theta(p, 0.25);
    if (q > 5) { p += (k*3 + 7) ^ 5; }
    q = cq_theta(q, 0.9);
    return cq_measure(p) + cq_measure(q);
}
int main(void) { (void)slice(); return 0; }
