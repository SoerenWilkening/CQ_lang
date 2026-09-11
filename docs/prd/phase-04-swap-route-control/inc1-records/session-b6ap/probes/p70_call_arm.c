/* (9) a-mux phi + a 6.5 CLASSICAL CALL arm */
#include "CQ.h"
__attribute__((noinline,const)) static int f(int x){ return x*3+1; }
int main(void) {
    int a = 5; int b0 = 0; int k = 4; int r = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3){ r = f(k); }
    return cq_measure(b0) + cq_measure(a) + cq_measure(r);
}
