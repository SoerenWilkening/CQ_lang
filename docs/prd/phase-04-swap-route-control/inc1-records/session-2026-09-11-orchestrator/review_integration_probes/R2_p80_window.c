/* p80 + the 9pum round-2 window: two SOURCE thetas on the %out at round 1, ONE rail at final taint */
#include "CQ.h"
__attribute__((noinline,const)) static int f(int x){ return x*3+1; }
int main(void) {
    volatile int kv = 4; int k = kv;
    int q = cq_theta(0, 0.5);
    int r = 0;
    if (q == 1) r = f(k);
    int b  = cq_theta(r, 0.25);
    int b3 = cq_theta(r, 0.9);
    int a = 5; bool b1 = 0;
    if (b == 13) a -= 3;
    if (a >= 3) b1 = cq_theta(b1, 0.5);
    return cq_measure(q) + cq_measure(b3) + cq_measure(b1) + cq_measure(a);
}
