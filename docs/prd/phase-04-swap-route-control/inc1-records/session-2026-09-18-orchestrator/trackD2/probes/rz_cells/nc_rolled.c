/* NON-CANCELLING variant of m_rz_eq_rz, ROLLED: the prefix/suffix global phases are
   +0.125 and +0.3, so they do NOT sum to zero. Tests whether the two sides agree for
   a structural reason or only because the matrix picked +-0.125. */
#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    a = cq_theta(a, 0.5);
    for (int i = 0; i < 2; ++i) {
        cq_phi(0.125);
        if (a == 5) { cq_phi(M_PI); }
        cq_phi(0.3);
    }
    return cq_measure(a);
}
int main(void){(void)slice();return 0;}
