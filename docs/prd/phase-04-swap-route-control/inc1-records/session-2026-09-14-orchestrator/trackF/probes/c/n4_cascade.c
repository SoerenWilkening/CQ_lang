/* N=4 — the claim is generality over N, so measure N=4 as well as N=3. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0 = 0; bool b1 = 0; bool b2 = 0; bool b3 = 0;
    b0 = cq_theta(b0, 0.5);
    if (b0) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;
    if (a >= 3) { b2 = cq_theta(b2, 0.5); }
    if (b2) a -= 3;
    if (a >= 3) { b3 = cq_theta(b3, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2) + cq_measure(b3) + cq_measure(a);
}
