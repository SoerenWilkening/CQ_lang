/* unpeeled twin of R1_p80_bool.c: the `a` mux deleted, the prep's guard spelled
   directly as the predicate -O1 folds `a >= 3` into. ONE merge phi, no peel. */
#include "CQ.h"
__attribute__((noinline,const)) static int f(int x){ return x*3+1; }
int main(void) {
    volatile int kv = 4; int k = kv;
    int q = cq_theta(0, 0.5);
    int r = 0;
    if (q == 1) r = f(k);
    bool b1 = 0;
    if (r != 13) b1 = cq_theta(b1, 0.5);
    return cq_measure(q) + cq_measure(r) + cq_measure(b1);
}
