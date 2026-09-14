#include "CQ.h"
/* the precedence graph with ALL THREE region kinds on ONE prep phi: the kickback
   (Precedes[kickback]={prep}) and the 4.4 select (Precedes[prep]={select}).
   Kahn must order kickback -> prep -> select with no cycle. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    int a = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1) cq_phi(0.3);
    a = b1 ? 2 : 5;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
