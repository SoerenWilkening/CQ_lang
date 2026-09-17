#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    int r = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    if (a == 5) { r = cq_theta(r, 0.9); }
    cq_phi(0.125);
    if (a == 5) { r = cq_theta(r, 0.9); }
    cq_phi(0.125);
    return cq_measure(a) + cq_measure(r);
}
int main(void){(void)slice();return 0;}
