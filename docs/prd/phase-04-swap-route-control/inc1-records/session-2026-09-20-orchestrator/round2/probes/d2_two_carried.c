/* d2: TWO carried handles in one loop, cross-reading. */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5, c = 9;
    for (int i = 0; i < 3; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) a -= 3;
        if (b) c -= 1;
    }
    return cq_measure(a) + cq_measure(c);
}
int main(void) { (void) run(); return 0; }
