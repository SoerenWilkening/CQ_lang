/* p3 — two carried registers: b (bool, condition) and r (int, rotated). */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  r = cq_theta(3, 0.1);
    for (int i = 0; i < 3; i++) {
        if (b) cq_phi(0.7);
        b = cq_theta(b, 0.2);
        r = cq_theta(r, 0.3);
    }
    return cq_measure(b) + cq_measure(r);
}
