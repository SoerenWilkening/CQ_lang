/* c4: the carried handle's exit value read on BOTH the break edge and the
   normal exit edge (two out-of-loop readers, one exit phi). */
#include "CQ.h"
__attribute__((noinline))
int run(int x) {
    int a = 5;
    for (int i = 0; i < 4; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) a -= 3;
        if (i == x) break;
    }
    int m = cq_measure(a);
    return m;
}
int main(void) { (void) run(2); return 0; }
