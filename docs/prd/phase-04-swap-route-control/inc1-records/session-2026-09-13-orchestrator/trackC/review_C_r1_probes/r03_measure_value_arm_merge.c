/* r03 — item 1: measure the merge of a VALUE arm (controlled-copy merge). */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int a = 2;
    if (q == 3) a = 5;
    return cq_measure(a) + cq_measure(q);
}
