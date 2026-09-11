#include "CQ.h"
int main(void) {
    int q = cq_theta(0, 0.3);
    int r = 5;
    if (q == 5) { r = cq_theta(5, 0.9); }
    return cq_measure(r) + cq_measure(q);
}
