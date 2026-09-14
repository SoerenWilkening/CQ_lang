/* twin of b9 at the ACTUAL runtime trip count (argc==1 => m==1 => one trip) */
#include "CQ.h"
int slice(int n) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    (void)n;
    s += cq_measure((y >> 1) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }
