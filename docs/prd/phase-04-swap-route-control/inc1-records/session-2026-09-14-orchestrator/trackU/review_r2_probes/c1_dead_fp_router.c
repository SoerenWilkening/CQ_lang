#include "CQ.h"
int main(void) {
    double u; double q = cq_theta(u, 0.5);
    double r; int c = 1;
    if (c) r = q; else r = q;            /* one-register router */
    double g; g = cq_theta(g, 0.7);      /* the chained read is GONE: r is dead */
    (void) r;
    return (int) cq_measure(q) + (int) cq_measure(g);
}
