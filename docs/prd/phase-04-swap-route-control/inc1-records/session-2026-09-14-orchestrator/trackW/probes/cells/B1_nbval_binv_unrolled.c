#include "CQ.h"
#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    _Bool b = 0;
    a = cq_theta(a, 0.5);
    b = cq_theta(b, 0.5);
    if (!b) { a = a - 3; }
    if (!b) { a = a - 3; }
    return cq_measure(a) + (int) cq_measure(b);
}
int main(void){(void)slice();return 0;}
