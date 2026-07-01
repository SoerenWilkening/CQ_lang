#include <CQ.h>
#include <math.h>

int demo(int seed) {
    double x = 0.0;
    x = cq_theta(x, 0.5);      // x tainted (quantum)
    int e;
    double m = frexp(x, &e);   // by-ref: returns mantissa, writes exponent to *e
    int mi = cq_measure((int)m);
    int ei = cq_measure(e);
    return mi + ei;
}
