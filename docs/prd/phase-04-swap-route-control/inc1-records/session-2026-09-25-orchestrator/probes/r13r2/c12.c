#include "CQ.h"
static const int tbl[4] = {1, 2, 3, 4};
static int slice(int u, int t, volatile int *jp) {
    int q = cq_theta(u, 0.5);
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(t, 0.5);
    int v = 7, w = 8;
    if (r < 9) {
        bool e; int s;
        if (q > 5) { e = b;    s = *jp; }
        else       { e = true; s = 0; }
        if (!e) { v = tbl[s & 3]; w = tbl[(s + 1) & 3]; }
        else    { v = 5;         w = 6; }
    }
    return cq_measure(v) + cq_measure(w) + cq_measure(b);
}
static volatile int J = 2;
int main(int argc, char **argv){ (void)argv; return slice(argc, argc+1, &J); }
