/* b3: carried handle + TAINTED (7.4) value-arm break on a separate rail. */
#include "CQ.h"
__attribute__((noinline))
int run(int seed, int n) {
    int a = 5;
    int q = cq_theta(seed, 0.25);
    bool b0[4];
    for (int i = 0; i < n; ++i) {
        q = q ^ 5;
        if (q == 7) break;
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    return cq_measure(a) + cq_measure(q);
}
int main(void) { (void) run(3, 4); return 0; }
