/* r32 — a break loop AND a classical measure in the same function. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.0);
    int out = 0; int k = 12;
    for (int i = 0; i < 4; ++i) {
        b = cq_theta(b, 0.5);
        if (b) { out = 7; break; }
    }
    return cq_measure(out) + cq_measure(k);
}
