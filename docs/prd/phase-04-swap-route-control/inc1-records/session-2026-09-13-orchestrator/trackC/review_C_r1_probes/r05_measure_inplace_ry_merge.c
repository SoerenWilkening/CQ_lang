/* r05 — item 1: measure the merge of an in-place controlled-Ry arm (M-beta RAUW target). */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int q = 0;
    q = cq_theta(q, 0.25);
    if (b) q = cq_theta(q, 0.5);
    return cq_measure(q) + cq_measure(b);
}
