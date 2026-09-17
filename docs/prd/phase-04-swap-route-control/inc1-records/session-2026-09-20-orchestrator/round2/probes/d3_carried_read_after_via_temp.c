/* d3: the carried handle's exit value read through a post-loop TEMP. */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    for (int i = 0; i < 3; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) a -= 3;
    }
    int t = a * 2;
    return cq_measure(t);
}
int main(void) { (void) run(); return 0; }
