#include "CQ.h"
int slice(void) {
    int tbl[8] = {0,1,2,3,4,5,6,7};
    int y = cq_theta(5, 0.5);
    int s = 0;
    s += cq_measure(tbl[(y >> 1) & 7]);
    s += cq_measure(tbl[(y >> 2) & 7]);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
