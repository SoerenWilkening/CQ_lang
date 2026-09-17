/* SUBJECT (C) ATTACK — THE BREAK TEST BETWEEN A MINT AND ITS DISCHARGE.
   `d` is minted from `y` BEFORE the break test and read AFTER it, so the per-trip
   rail group cannot be atomic in one block: the mint's block and the read's block
   are separated by a classical early exit. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k) & 1;             /* MINT */
        if (k >= lim) break;              /* CLASSICAL early exit, between */
        s += cq_measure(d);               /* the only READ — after the exit */
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
