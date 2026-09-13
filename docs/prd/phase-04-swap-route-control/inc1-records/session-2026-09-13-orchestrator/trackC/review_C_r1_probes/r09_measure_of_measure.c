/* r09 — item 2: cq_measure of a cq_measure result, and of measure-derived arithmetic. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int m = cq_measure(q);
    int n = m + 1;
    return cq_measure(n) + cq_measure(m);
}
