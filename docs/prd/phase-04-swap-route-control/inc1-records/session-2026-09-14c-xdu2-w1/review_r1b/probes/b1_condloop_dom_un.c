/* hand-unrolled twin of b1_condloop_dom (K=2) */
#include "CQ.h"
int slice(int c) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    if (c) {
        s += cq_measure((y >> 1) & 1);
        s += cq_measure((y >> 2) & 1);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }
