#include "CQ.h"
#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    int r = 7;
    _Bool b = 0;
    a = cq_theta(a, 0.5);
    b = cq_theta(b, 0.5);
    if (b) { r = cq_theta(7, 0.9); }
    if (b) { r = cq_theta(7, 0.9); }
    return cq_measure(a) + cq_measure(r) + (int) cq_measure(b);
}
int main(void){(void)slice();return 0;}
