/* SUBJECT (B) ATTACK — r3 with the OUTER loop's icmp rail MEASURE-OWNED removed:
   here the outer's own compare rail feeds an accumulator, so `railIsInterior` is
   true and conjunct (3) must reach it THROUGH the nest. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    int acc = 0;
    for (int i = 1; i <= 2; ++i) {
        acc += (y > i);                       /* interior: not measure-owned */
        for (int j = 0; j < 2; ++j) {
            int u = cq_theta(6, 0.4);
            s += cq_measure((u >> j) & 1);
        }
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(acc) + cq_measure(y);
}
int main(void) { return slice(); }
