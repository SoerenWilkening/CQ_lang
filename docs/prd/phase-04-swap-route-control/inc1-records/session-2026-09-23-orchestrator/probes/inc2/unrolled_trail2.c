#include "CQ.h"
static int slice(void) {
    int A=5,B=6,C=7,D=8; bool b0=0,b1=0,b2=0; bool t=0;
    b0 = cq_theta(b0, 0.5); if (b0) { A-=3; B-=4; C-=5; D-=6; } t = cq_theta(b0, -0.5);
    b1 = cq_theta(b1, 0.5); if (b1) { A-=3; B-=4; C-=5; D-=6; } t = cq_theta(b1, -0.5);
    b2 = cq_theta(b2, 0.5); if (b2) { A-=3; B-=4; C-=5; D-=6; } t = cq_theta(b2, -0.5);
    return cq_measure(A)+cq_measure(B)+cq_measure(C)+cq_measure(D)+cq_measure(t);
}
int main(void){(void)slice();return 0;}
