/* r22 — item 3: a classical float/f80 measure (no rail may be minted). */
#include "CQ.h"
int main(void) {
    float f = 1.5f;
    long double g = 2.5L;
    int q = cq_theta(3, 0.5);
    return (int)cq_measure(f) + (int)cq_measure(g) + cq_measure(q);
}
