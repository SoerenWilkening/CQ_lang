/* a 4.4 select INSIDE a bounded loop whose condition is a prep merge phi from
   OUTSIDE the loop: rung 0 passes (the prep region is flat and claimed), and the
   select's stream is minted per iteration. The in-loop ternary on a COMPARE is a
   shipped shape (gate 2c prong (b) / slice_control_select_loop); on a phi it is
   new with this increment. */
#include "CQ.h"
int main(void) {
    int a = 5; int acc = 0; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    for (int i = 0; i < 3; ++i) { int t = b1 ? i : 5; acc += cq_measure(t); }
    return cq_measure(b0) + cq_measure(b1) + acc;
}
