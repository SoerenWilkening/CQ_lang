#include "CQ.h"
int main(void) {
    int Z = 5, P = 0, Q = 1, R = 2;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) { Z -= 3; P += 2; Q ^= 7; R += 5; }
    }
    return cq_measure(Z) + cq_measure(P) + cq_measure(Q) + cq_measure(R);
}
