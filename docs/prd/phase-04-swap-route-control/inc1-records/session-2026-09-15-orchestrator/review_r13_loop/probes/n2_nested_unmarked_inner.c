/* R13-r2 N2 — THE CONTROL for N1: identical outer loop, but the INNER loop reads
   `y` (defined outside it), so `markIfIterationLocal` refuses it and NOTHING in
   `L_outer->blocks()` is marked.  Conjunct (1) is then false and conjunct (3)
   reaches the outer body rail. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 1; i <= 2; ++i) {
        s += cq_measure((y >> i) & 1);
        for (int j = 0; j < 2; ++j)
            s += cq_measure((y >> (j + 8)) & 1);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
