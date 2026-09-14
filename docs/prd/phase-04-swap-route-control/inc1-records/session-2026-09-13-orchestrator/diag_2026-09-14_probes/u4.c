#include "CQ.h"

int main(void) {
    int a;
    bool b0 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0) a -= 3;
    return cq_measure(b0) + cq_measure(a);
}
