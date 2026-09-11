/* the same window but the fused diamond's condition is a BARE _Bool RAIL off the %out */
#include "CQ.h"
__attribute__((noinline,const)) static int f(int x){ return x!=0; }
int main(void) {
    volatile int kv = 4; int k = kv;
    int q = cq_theta(0, 0.5);
    int r = 0;
    if (q == 1) r = f(k);
    bool s  = (bool)r;
    bool b  = cq_theta(s, 0.25);
    bool b3 = cq_theta(s, 0.9);
    int a = 5; bool b1 = 0;
    if (b) a -= 3;
    if (a >= 3) b1 = cq_theta(b1, 0.5);
    return cq_measure(q) + cq_measure(b3) + cq_measure(b1) + cq_measure(a);
}
