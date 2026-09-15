/* b05 — b02 with the accumulator kept CLASSICAL (the arm does not feed `a`):
   isolates "is it `a`'s taint, or the loop shape?" */
#include "CQ.h"
int main(void) {
    int a = 5; int s = 0;
    for (int i = 0; i < 3; ++i) {
        bool b = 0;
        if (a >= 3) b = cq_theta(b, 0.5);
        s += cq_measure(b);
    }
    return s + a;
}
