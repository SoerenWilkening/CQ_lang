/* c2: carried handle + CLASSICAL runtime break BEFORE the region arm. */
#include "CQ.h"
__attribute__((noinline))
int run(int x) {
    int a = 5;
    for (int i = 0; i < 4; ++i) {
        if (i == x) break;
        bool b = cq_theta((bool)0, 0.5);
        if (b) a -= 3;
    }
    return cq_measure(a);
}
int main(void) { (void) run(2); return 0; }
