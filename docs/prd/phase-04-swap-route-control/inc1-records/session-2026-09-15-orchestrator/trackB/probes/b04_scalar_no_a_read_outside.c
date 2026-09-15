/* b04 — b02 with `a` NOT read outside the loop: the ONLY change from b02.
   If (c3) is the wall, this one flips. */
#include "CQ.h"
int main(void) {
    int a = 5; int s = 0;
    for (int i = 0; i < 3; ++i) {
        bool b = 0;
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) a -= 3;
        s += cq_measure(b);
    }
    return s;
}
