/* b02 — the owner's loop with a SCALAR iteration-local bool (no bank at all),
   measuring `a` AFTER the loop. Isolates wx8g (c3) from the bank entirely. */
#include "CQ.h"
int main(void) {
    int a = 5; int s = 0;
    for (int i = 0; i < 3; ++i) {
        bool b = 0;
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) a -= 3;
        s += cq_measure(b);
    }
    return s + cq_measure(a);
}
