#include "CQ.h"
int main(void) {
    int r = cq_theta(0, 0.3);
    bool c = cq_theta(false, 0.5);
    int a = 9;
    if (!c) { a = r; r = cq_theta(r, 0.5); }
    return cq_measure(r) + cq_measure(a);
}
