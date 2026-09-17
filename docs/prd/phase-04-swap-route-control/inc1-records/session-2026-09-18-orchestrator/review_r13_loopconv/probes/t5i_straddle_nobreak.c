/* ISOLATING CONTROL for t5h: the SAME rail with two uses, BREAK DELETED.
   One-operand delta = the `if (k >= lim) break;` line. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    (void)lim;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        s += cq_measure(d & 1);
        s += cq_measure(d & 2);
    }
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
