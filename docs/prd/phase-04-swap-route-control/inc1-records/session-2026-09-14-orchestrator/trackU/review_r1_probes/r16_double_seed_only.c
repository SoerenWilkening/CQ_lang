/* control: undef seed, DEFINED angle at width double */
#include "CQ.h"
int main(void) {
    double s;
    double r = cq_theta(s, 0.5);
    return (int)cq_measure(r);
}
