/* d5: a RUNTIME zero-trip guard around the carried-handle loop -- (Z8). */
#include "CQ.h"
__attribute__((noinline))
int run(int n) {
    int a = 5;
    for (int i = 0; i < n && i < 3; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) a -= 3;
    }
    return cq_measure(a);
}
int main(void) { (void) run(3); return 0; }
