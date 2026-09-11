/* p24 — the rail's SEED measured BEFORE the loop; the condition is the header phi. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int acc = cq_measure(b);
    for (int i = 0; i < 3; i++) { if (b) cq_phi(0.7); b = cq_theta(b, 0.2); }
    return acc + cq_measure(b);
}
