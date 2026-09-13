#include "CQ.h"
int main(void) {
    int b0 = 0;
    bool b1 = 0;
    b0 = cq_theta(b0, 0.5);
    if (b0 == 1) { b1 = cq_theta(b1, 0.5); }
    return cq_measure(b0) + cq_measure(b1);
}
