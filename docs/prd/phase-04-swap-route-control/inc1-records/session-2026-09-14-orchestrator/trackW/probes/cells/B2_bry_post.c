#include "CQ.h"
#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    int r = 0;
    _Bool b = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    b = cq_theta(b, 0.5);
    for (int i = 0; i < 2; ++i) {
        if (b) { r = cq_theta(r, 0.9); }
        a = cq_theta(a, -0.5);
    }
    return cq_measure(a) + cq_measure(r) + (int) cq_measure(b);
}
int main(void){(void)slice();return 0;}
