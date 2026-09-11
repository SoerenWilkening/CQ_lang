// W10 — the ROUND-2 peel's mux ESCAPES (a store to a global). The round-2 peel
// passes Delta=nullptr; its growth is supposed to be covered by
// repropagateControlMerges' own `reseed`.
#include "CQ.h"
int g_probe;
__attribute__((noinline,const)) static int f(int x){ return x*3+1; }
int main(void) {
    volatile int kv = 4; int k = kv;
    int q = cq_theta(0, 0.5);
    int r = 0;
    if (q == 1) r = f(k);
    int a = 5, c = 1;
    if (r == 13) { a -= 3; c = 2; }
    g_probe = c;                       // the round-2 peeled mux escapes
    return cq_measure(q) + cq_measure(r) + cq_measure(a);
}
