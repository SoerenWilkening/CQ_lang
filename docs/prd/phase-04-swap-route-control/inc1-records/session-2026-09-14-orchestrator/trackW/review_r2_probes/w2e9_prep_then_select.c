/* R2-E9 — COMPOSITION with Track M (bd boi6/8xaw): an in-loop bare-`_Bool`
   controlled STATE PREP whose merge phi is then the CONDITION of a 4.4 data
   select, all inside the rolled loop. */
#include "CQ.h"
int slice(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    int  a = 7;
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        bool b1 = 0;
        if (b0) b1 = cq_theta((bool)0, 0.25);
        if (b1) a -= 3;
        s += 1;
    }
    return s + cq_measure(a) + cq_measure(b0);
}
int main(void) { return slice(); }
