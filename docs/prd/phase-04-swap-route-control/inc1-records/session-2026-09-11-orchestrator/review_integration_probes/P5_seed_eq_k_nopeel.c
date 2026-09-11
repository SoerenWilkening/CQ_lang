#include "CQ.h"
int slice(int q) {
    int r = 5;
    if (q == 5) { r = cq_theta(5, 0.9); }
    return cq_measure(r) + cq_measure(q);
}
int main(void){ int q = cq_theta(0, 0.3); return slice(q); }
