/* d4: the region CONDITION reads the carried register (the owner's shape,
   bank-free). */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    for (int i = 0; i < 3; ++i) {
        bool b = 0;
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) a -= 3;
    }
    return cq_measure(a);
}
int main(void) { (void) run(); return 0; }
