#include "CQ.h"
#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    _Bool b = 0;
    a = cq_theta(a, 0.5);
    b = cq_theta(b, 0.5);
    b = cq_theta(b, 0.25);
    if (!b) { cq_phi(M_PI); }
    b = cq_theta(b, 0.25);
    if (!b) { cq_phi(M_PI); }
    return cq_measure(a) + (int) cq_measure(b);
}
int main(void){(void)slice();return 0;}
