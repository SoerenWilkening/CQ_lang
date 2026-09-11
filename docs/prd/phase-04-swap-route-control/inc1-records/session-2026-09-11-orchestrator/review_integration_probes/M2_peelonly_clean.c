#include "CQ.h"
int main(void) {
    int a = 5; int z = 1;
    bool b0 = cq_theta((bool)0, 0.5);
    if (b0 == 1) { a -= 3; z = 4; }
    return cq_measure(b0) + cq_measure(a) + cq_measure(z);
}
