#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    a = cq_theta(a, 0.5);
    if (a == 5) { cq_phi(M_PI); }
    if (a == 5) { cq_phi(M_PI); }
    return cq_measure(a);
}
int main(void){(void)slice();return 0;}
