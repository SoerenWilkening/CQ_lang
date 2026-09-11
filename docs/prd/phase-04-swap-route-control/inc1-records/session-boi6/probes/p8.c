/* p8 — NEGATED carried bool as the loop region's condition. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 3; i++) { if (!b) cq_phi(0.7); b = cq_theta(b, 0.2); }
    return cq_measure(b);
}
