// W13 — the ROUND-2 peel's mux is the argument of a Phase-6 candidate (the `r20`
// shape one round later).
#include "CQ.h"
__attribute__((noinline,const)) static int f(int x){ return x*3+1; }
__attribute__((noinline)) static int helper(int x){ return x + 1; }
int main(void) {
    volatile int kv = 4; int k = kv;
    int q = cq_theta(0, 0.5);
    int r = 0;
    if (q == 1) r = f(k);
    int a = 5, c = 1;
    if (r == 13) { a -= 3; c = 2; }
    int t = helper(c);
    return cq_measure(q) + cq_measure(r) + cq_measure(a) + cq_measure(t);
}
