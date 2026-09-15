#include "CQ.h"
int ka(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    s += cq_measure((y >> 1) & 1);
    s += cq_measure((y >> 2) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int kb(void) {
    int y = cq_theta(6, 0.4);
    int p = y * 3;
    int s = 0;
    s += cq_measure((p >> 1) & 1);
    s += cq_measure((p >> 2) & 1);
    return s + cq_measure(y);
}
int main(void) { return ka() + kb(); }
