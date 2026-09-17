/* c1: carried handle + CLASSICAL runtime break AFTER the region arm. */
#include "CQ.h"
__attribute__((noinline))
int run(int x) {
    int a = 5;
    for (int i = 0; i < 4; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) a -= 3;
        if (i == x) break;
    }
    return cq_measure(a);
}
int main(void) { (void) run(99); return 0; }
