/* p26 — carried bool condition + carried INT register rotated in the body. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  q = cq_theta(5, 0.1);
    for (int i = 0; i < 3; i++) { if (b) cq_phi(0.7); b = cq_theta(b, 0.2); q = cq_theta(q, 0.3); }
    return cq_measure(b) + cq_measure(q);
}
