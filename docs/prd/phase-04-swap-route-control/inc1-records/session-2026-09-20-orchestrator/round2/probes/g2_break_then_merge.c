/* g2: a 7.4 break loop whose escape value then feeds a 4.4 data select whose
   result is the latch incoming of an enclosing carried handle. */
#include "CQ.h"
__attribute__((noinline))
int run(int seed) {
    int a = 5;
    for (int j = 0; j < 2; ++j) {
        int q = cq_theta(seed, 0.25);
        for (int i = 0; i < 4; ++i) {
            q = q ^ 5;
            if (q == 7) break;
        }
        bool b = cq_theta((bool)0, 0.5);
        if (b) a = q;
    }
    return cq_measure(a);
}
int main(void) { (void) run(3); return 0; }
