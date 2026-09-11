/* p6 — the 4.4 DATA select on a CARRIED bool inside a loop. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; i++) {
        int a = b ? 2 : 5;
        acc += a;
        b = cq_theta(b, 0.2);
    }
    return acc + cq_measure(b);
}
