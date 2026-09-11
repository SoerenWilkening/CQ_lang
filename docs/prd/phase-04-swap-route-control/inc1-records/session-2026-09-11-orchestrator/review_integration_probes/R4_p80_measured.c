/* p80 + A.1 rung (ii): the round-2 condition register measured before the peeled select */
#include "CQ.h"
__attribute__((noinline,const)) static int f(int x){ return x*3+1; }
int main(void) {
    volatile int kv = 4; int k = kv;
    int q = cq_theta(0, 0.5);
    int r = 0;
    if (q == 1) r = f(k);
    int m = cq_measure(r);
    int a = 5; bool b1 = 0;
    if (r == 13) a -= 3;
    if (a >= 3) b1 = cq_theta(b1, 0.5);
    return m + cq_measure(q) + cq_measure(b1) + cq_measure(a);
}
