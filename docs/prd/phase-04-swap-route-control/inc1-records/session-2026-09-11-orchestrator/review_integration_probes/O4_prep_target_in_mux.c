#include "CQ.h"
int main(void) {
    bool b1 = cq_theta(false, 0.2);
    bool c = cq_theta(false, 0.5);
    int a;
    if (c) { a = b1; } else { b1 = cq_theta(b1, 0.5); a = 9; }
    return cq_measure(a) + cq_measure(b1) + cq_measure(c);
}
