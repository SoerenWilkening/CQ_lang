/* d1: a dtzb IN-PLACE add on the carried register, beside the merge. */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    for (int i = 0; i < 3; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        a = a + 1;
        if (b) a -= 3;
    }
    return cq_measure(a);
}
int main(void) { (void) run(); return 0; }
