#include "CQ.h"
int slice(void) {
    int Z = 5, P = 0;
    for (int i = 0; i < 3; ++i) {
        int q = cq_theta(0, 0.5);
        if (q > 2) { Z -= 3; P += 2; }
    }
    return cq_measure(Z) + cq_measure(P);
}
