/* hand-unrolled twin (K=2) of t2 */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    s += cq_measure((y >> 1) & 1);
    s += cq_measure((y >> 2) & 1);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
