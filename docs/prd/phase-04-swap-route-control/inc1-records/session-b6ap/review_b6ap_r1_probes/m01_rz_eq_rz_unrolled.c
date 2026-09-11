#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    a = cq_theta(a, 0.5);
    cq_phi(0.125);
    if (a == 5) { cq_phi(M_PI); }
    cq_phi(-0.125);
    cq_phi(0.125);
    if (a == 5) { cq_phi(M_PI); }
    cq_phi(-0.125);
    return cq_measure(a);
}
int main(void){(void)slice();return 0;}
