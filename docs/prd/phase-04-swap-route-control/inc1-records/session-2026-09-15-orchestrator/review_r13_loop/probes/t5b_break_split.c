/* R13-r2 T-5 (b): a break loop whose body CANNOT be if-converted into one block —
   a second gate group after the break test.  Does any `_unc`/`cqrt_free` land in a
   block its forward mint does not dominate, or in the loop EXIT (1 adjoint / K mints)? */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        s += cq_measure((y >> k) & 1);
        if (s > 1) break;
        s += cq_measure((y >> (k + 8)) & 1);
        s += cq_measure((y >> (k + 16)) & 1);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
