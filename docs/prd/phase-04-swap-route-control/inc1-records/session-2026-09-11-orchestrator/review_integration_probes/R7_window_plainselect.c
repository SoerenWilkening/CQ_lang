/* the 9pum shape verbatim but with a 6.5 arm as the taint source (no peel) -- control */
#include "CQ.h"
__attribute__((noinline,const)) static int f(int x){ return x*3+1; }
int main(void) {
    volatile int kv = 4; int k = kv;
    int q = cq_theta(0, 0.5);
    int r = 0;
    if (q == 1) r = f(k);
    int b  = cq_theta(r, 0.25);
    int b3 = cq_theta(r, 0.9);
    int a = (b == 13) ? 2 : 5;
    return cq_measure(q) + cq_measure(b3) + cq_measure(a);
}
