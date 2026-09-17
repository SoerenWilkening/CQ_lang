/* b4: carried handle read on BOTH the break edge and the normal exit edge. */
#include "CQ.h"
__attribute__((noinline))
int run(int n) {
    int a = 5;
    bool b0[4];
    int r = 0;
    for (int i = 0; i < n; ++i) {
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
        if (i == 2) { r = cq_measure(a); goto out; }
    }
    r = cq_measure(a);
out:
    return r;
}
int main(void) { (void) run(4); return 0; }
