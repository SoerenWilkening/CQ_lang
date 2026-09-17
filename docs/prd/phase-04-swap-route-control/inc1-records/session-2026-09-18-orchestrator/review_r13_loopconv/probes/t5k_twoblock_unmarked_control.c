/* ISOLATING CONTROL for t5j: the SAME two-block body, but the temp ESCAPES the
   loop, so `railLocalQualifies` refuses the marking and conjunct (1) cannot
   suppress.  If this DECLINES with the dephasing string while t5j accepts, the
   MARKING is the door, not the shape. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    int last = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        last = d & 4;                          /* escapes the loop */
        s += cq_measure(d & 1);
        if (k < lim) s += cq_measure(d & 2);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(last) + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
