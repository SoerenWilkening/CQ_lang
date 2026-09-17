/* c5: a THREE-exit loop around the carried handle. */
#include "CQ.h"
__attribute__((noinline))
int run(int x, int y) {
    int a = 5;
    for (int i = 0; i < 4; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) a -= 3;
        if (i == x) break;
        if (i == y) break;
    }
    return cq_measure(a);
}
int main(void) { (void) run(2, 3); return 0; }
