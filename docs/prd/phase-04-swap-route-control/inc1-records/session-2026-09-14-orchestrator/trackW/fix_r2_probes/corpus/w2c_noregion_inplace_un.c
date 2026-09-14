/* hand-unrolled twin of w2c_noregion_inplace (K=2) */
#include "CQ.h"
int slice(void) {
    int q = cq_theta(5, 0.5);
    int s = 0;
    { q = q + 3; s += cq_measure(q); }
    { q = q + 3; s += cq_measure(q); }
    return s;
}
int main(void) { return slice(); }
