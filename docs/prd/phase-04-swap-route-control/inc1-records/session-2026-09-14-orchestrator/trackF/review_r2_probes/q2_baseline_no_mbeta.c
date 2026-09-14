/* Q2 — the isolating control for Q1: identical but with region A REMOVED, so no
   M-beta RAUW exists. Any Q1-vs-Q2 verdict difference is attributable to A. */
#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int a = argc + 4;
    bool b0 = 0, b1 = 0;
    b0 = cq_theta(b0, 0.5);
    if (b0) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
