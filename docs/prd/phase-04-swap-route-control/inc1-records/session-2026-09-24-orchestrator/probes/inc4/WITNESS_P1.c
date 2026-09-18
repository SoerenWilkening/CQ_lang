#include "CQ.h"
static const int c[4] = {11, 22, 33, 44};
int probe(long n) {
    int q = cq_theta(0, 0.5);
    int Z = cq_theta(5, 0.25);
    int P = cq_theta(0, 0.25);
    if (q > 2) {
        long idx;
        if (q > 7) { long t = (n*3+7)^5;  t = (t*11+3)^9; t = (t*5+1)^3; idx = t & 3; }
        else       { long u = (n*13+2)^7; u = (u*17+5)^1; u = (u*7+9)^4; idx = u & 3; }
        Z -= c[idx];
        P += c[idx];
    }
    return Z + P;                 /* COHERENT escape: no cq_measure, non-main */
}
int main(void) { return probe(2); }
