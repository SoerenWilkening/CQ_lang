#include <CQ.h>
#include <math.h>
int main(void) {
    double x = cq_theta(0.0, 0.5);
    int e;
    double m = frexp(x, &e);   // e (exponent producer) is DEAD -> must uncompute
    return cq_measure((int)m); // only mantissa measured
}
