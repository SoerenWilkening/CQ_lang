#include "CQ.h"
int slice(int a) {
    bool b0 = 0;
    bool b1 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
int main(void){ return slice(5); }
