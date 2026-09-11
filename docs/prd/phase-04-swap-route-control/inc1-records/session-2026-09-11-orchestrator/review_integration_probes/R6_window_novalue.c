/* the round-2 window with a pure DATA mux only (no prep): peel + A.1 compare re-verify */
#include "CQ.h"
__attribute__((noinline,const)) static int f(int x){ return x*3+1; }
int main(void) {
    volatile int kv = 4; int k = kv;
    int q = cq_theta(0, 0.5);
    int r = 0;
    if (q == 1) r = f(k);
    int b  = cq_theta(r, 0.25);
    int b3 = cq_theta(r, 0.9);
    int a = 5; int z = 1;
    if (b == 13) { a -= 3; z = 4; }
    return cq_measure(q) + cq_measure(b3) + cq_measure(z) + cq_measure(a);
}
