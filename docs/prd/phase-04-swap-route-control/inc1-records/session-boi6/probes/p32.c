/* p32 — carried bool read as DATA in the body beside the region. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int q = cq_theta(0, 0.3);
    for (int i = 0; i < 3; i++) {
        if (b) cq_phi(0.7);
        if (b == 1) q = cq_theta(q, 0.1);
        b = cq_theta(b, 0.2);
    }
    return cq_measure(b) + cq_measure(q);
}
