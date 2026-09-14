/* R2-C — the `offset.ll` shape with the NEW bare-`_Bool` condition: a (b')
   rail region PLUS a dtzb IN-PLACE self-update on a second carried register.
   The in-place `add` is the loop's ONLY tainted non-excluded instruction, so
   the F-W1-3 exclusion is what decides whether conjunct 2 is asked at all. */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  q = cq_theta(5, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        if (b) r = cq_theta(r, 0.3);
        q = q + 3;
        s += cq_measure(q);
    }
    return s + cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
