#include "CQ.h"
int main(void) {
    bool b1 = cq_theta((bool)0, 0.2);
    bool b0 = cq_theta((bool)0, 0.5);
    int d = (int)b1 * 2;
    int a;
    if (b0) { a = 9; } else { b1 = cq_theta(b1, 0.5); a = d; }
    return cq_measure(a) + cq_measure(b1) + cq_measure(b0);
}
