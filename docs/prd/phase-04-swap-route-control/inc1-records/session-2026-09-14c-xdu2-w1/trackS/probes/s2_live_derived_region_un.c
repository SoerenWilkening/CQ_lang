/* hand-unrolled twin (K=2) of s2 */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int p = y * 3;
    int s = 0;
    if ((p >> 1) & 1) cq_phi(0.3);
    if ((p >> 2) & 1) cq_phi(0.3);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
