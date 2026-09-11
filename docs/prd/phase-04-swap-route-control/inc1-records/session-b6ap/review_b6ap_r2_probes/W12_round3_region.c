// W12 — the ROUND-2 peel's mux becomes a THIRD region's condition (round 3).
#include "CQ.h"
__attribute__((noinline,const)) static int f(int x){ return x*3+1; }
int main(void) {
    volatile int kv = 4; int k = kv;
    int q = cq_theta(0, 0.5);
    int r = 0;
    if (q == 1) r = f(k);
    int a = 5, c = 1;
    if (r == 13) { a -= 3; c = 2; }
    int b1 = 0;
    if (c == 2) b1 = cq_theta(b1, 0.5);
    return cq_measure(q) + cq_measure(r) + cq_measure(a) + cq_measure(b1);
}
