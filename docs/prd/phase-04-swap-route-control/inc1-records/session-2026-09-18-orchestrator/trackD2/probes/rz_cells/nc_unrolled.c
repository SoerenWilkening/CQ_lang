/* NON-CANCELLING variant of m_rz_eq_rz, UNROLLED (hand-unrolled twin of nc_rolled.c). */
#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    a = cq_theta(a, 0.5);
    cq_phi(0.125);
    if (a == 5) { cq_phi(M_PI); }
    cq_phi(0.3);
    cq_phi(0.125);
    if (a == 5) { cq_phi(M_PI); }
    cq_phi(0.3);
    return cq_measure(a);
}
int main(void){(void)slice();return 0;}
