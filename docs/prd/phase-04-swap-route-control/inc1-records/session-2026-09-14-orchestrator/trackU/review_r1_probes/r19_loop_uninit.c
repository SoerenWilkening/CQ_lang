/* an undef seed inside a bounded loop: rolled vs the initialized twin */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    for (int i = 0; i < 3; i++) {
        if (b0) a -= 1;
    }
    bool b1;
    if (a >= 1){ b1 = cq_theta(b1, 0.25); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
