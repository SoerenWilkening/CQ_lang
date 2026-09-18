#include "CQ.h"
volatile int g_seed = 5;
static int slice(void) {
    int A=g_seed, B=g_seed, C=g_seed, D=g_seed;
    for (int i = 0; i < 3; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) { A-=3; B-=4; C-=5; D-=6; }
    }
    return cq_measure(A)+cq_measure(B)+cq_measure(C)+cq_measure(D);
}
int main(void){(void)slice();return 0;}
