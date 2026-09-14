/* opaque seed but CONSTANT select arms — discriminates "run-time arm" from "opaque cond" */
#include "CQ.h"
__attribute__((noinline)) int slice(int a) {
    bool b0 = 0;
    if (a >= 3) b0 = cq_theta(b0, 0.5);
    int r = b0 ? 2 : 5;
    return cq_measure(r) + cq_measure(b0);
}
int main(void){ return slice(5); }
