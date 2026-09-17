/* r3: post-loop non-diagonal gate on the LAST-TRIP condition rail `b`, which is
   entangled with the carried register through the controlled copies. */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    bool bl = 0;
    for (int i = 0; i < 3; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) a -= 3;
        bl = b;
    }
    bl = cq_theta(bl, -0.5);
    return cq_measure(a) + cq_measure(bl);
}
int main(void) { (void) run(); return 0; }
