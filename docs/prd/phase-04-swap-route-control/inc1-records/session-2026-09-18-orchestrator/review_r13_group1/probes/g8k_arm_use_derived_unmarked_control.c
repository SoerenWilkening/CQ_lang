/* ISOLATING CONTROL for g8 (the t5k trick): the SAME two-block body plus an
   ESCAPING iteration-local temp, so `railLocalQualifies` refuses the marking.
   If this DECLINES with the dephasing string while g8 accepts, the MARKING is
   the door for g8 too — i.e. conjunct (1)'s new second half returned TRUE on a
   body whose rails are NOT discharged. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    int last = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        last = d & 8;                       /* escapes the loop */
        s += cq_measure(d & 1);
        if (k < lim) { int e = d + 7; s += cq_measure(e & 2); }
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(last) + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
