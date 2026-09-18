#include "CQ.h"
static int slice(void) {
    int A=5,B=6,C=7,D=8; bool bb[3]; bool t=0;
    for (int i=0;i<3;++i) {
        bb[i] = cq_theta(bb[i], 0.5);
        if (bb[i]) { A-=3; B-=4; C-=5; D-=6; }
        t = cq_theta(bb[i], -0.5);       /* trailing NON-DIAGONAL on the condition's register */
    }
    return cq_measure(A)+cq_measure(B)+cq_measure(C)+cq_measure(D)+cq_measure(t);
}
int main(void){(void)slice();return 0;}
