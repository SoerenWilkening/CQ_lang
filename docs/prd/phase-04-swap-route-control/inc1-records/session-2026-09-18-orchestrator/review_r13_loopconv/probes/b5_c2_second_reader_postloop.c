/* ATTACK B5 on the c2 conversion: A SECOND READER OF THE PER-TRIP RAIL AFTER THE
   LOOP — the `(u>>1)` chain's value escapes the body. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    int last = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        last = (u >> 1) & 1;
        s += cq_measure(last) + cq_measure(y & 1);
        u = cq_theta(u, 0.9);
        s += cq_measure(u);
    }
    return s + cq_measure(last) + cq_measure(y);   /* <-- second reader, post-loop */
}
int main(void) { return slice(); }
