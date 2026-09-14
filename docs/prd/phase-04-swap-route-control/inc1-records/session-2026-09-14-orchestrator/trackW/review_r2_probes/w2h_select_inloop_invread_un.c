/* hand-unrolled twin (K=2) of R2-H1 */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  a = cq_theta(7, 0.25);
    int  s = 0;
    { int u = cq_theta(5, 0.5); a = b ? a - 3 : a; s += cq_measure(((u >> 1) & 1) + (int)b); }
    { int u = cq_theta(5, 0.5); a = b ? a - 3 : a; s += cq_measure(((u >> 1) & 1) + (int)b); }
    return s + cq_measure(a);
}
int main(void) { return slice(); }
