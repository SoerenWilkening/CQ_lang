/* hand-unrolled twin (K=2) of s3 */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    if ((y >> 1) & 1) cq_phi(0.3);
    if ((y >> 2) & 1) cq_phi(0.3);
    y = cq_theta(y, 0.9);
    return cq_measure(y);
}
int main(void) { return slice(); }
