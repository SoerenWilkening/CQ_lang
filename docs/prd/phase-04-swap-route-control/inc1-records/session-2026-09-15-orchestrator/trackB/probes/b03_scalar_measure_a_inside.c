/* b03 — b02 with `a` measured INSIDE the loop instead: no tainted value defined
   in L is read outside L. The (c3) discriminator. */
#include "CQ.h"
int main(void) {
    int a = 5; int s = 0;
    for (int i = 0; i < 3; ++i) {
        bool b = 0;
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) a -= 3;
        s += cq_measure(b) + cq_measure(a);
    }
    return s;
}
