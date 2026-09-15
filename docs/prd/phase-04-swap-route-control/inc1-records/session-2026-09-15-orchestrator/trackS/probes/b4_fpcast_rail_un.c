#include "CQ.h"
double slice(void) {
    double y = cq_theta(5.0, 0.5);
    double w = y;
    double s = 0;
    w = (double)(float)w; s += cq_measure(w);
    w = (double)(float)w; s += cq_measure(w);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return (int)slice(); }
