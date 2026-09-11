/* p18 — NESTED loops around a carried bool. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 2; i++)
        for (int j = 0; j < 2; j++) { if (b) cq_phi(0.7); b = cq_theta(b, 0.2); }
    return cq_measure(b);
}
