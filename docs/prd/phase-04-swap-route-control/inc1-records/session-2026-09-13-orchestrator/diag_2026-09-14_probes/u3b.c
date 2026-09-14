#include "CQ.h"

int main(void) {
    int a = 5;
    bool b0;
    b0 = cq_theta(b0, 0.5);
    if (b0) a -= 3;
    b0 = cq_theta(b0, -0.5);
    return cq_measure(b0) + cq_measure(a);
}
