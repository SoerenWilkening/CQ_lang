#include <CQ.h>
#include <math.h>
int demo_modf(void) {
    double x = cq_theta(0.0, 0.5);
    double ip;
    double fp = modf(x, &ip);          // frac returned, integer part → *ip (double)
    return cq_measure((int)fp) + cq_measure((int)ip);
}
int demo_remquo(void) {
    double x = cq_theta(0.0, 0.5);
    double y = cq_theta(0.0, 0.3);
    int q;
    double r = remquo(x, y, &q);        // remainder returned, quotient bits → *q (int)
    return cq_measure((int)r) + cq_measure(q);
}
