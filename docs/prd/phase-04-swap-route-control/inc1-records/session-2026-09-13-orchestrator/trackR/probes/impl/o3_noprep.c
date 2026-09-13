/* O3 with the bool prep REMOVED — isolates the quantum-incoming mux, which is
   the pre-existing 4.4 select path and must be identical on both binaries. */
#include "CQ.h"
int main(void) {
    int p = cq_theta(0, 0.3);
    int q = cq_theta(0, 0.7);
    bool c = cq_theta(false, 0.5);
    int a;
    if (c) { a = p; } else { a = q; }
    return cq_measure(a) + cq_measure(p) + cq_measure(q);
}
