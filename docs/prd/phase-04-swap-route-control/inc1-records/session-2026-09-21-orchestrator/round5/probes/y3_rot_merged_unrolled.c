// Y3 — Y1's HAND-UNROLLED twin (no loop at all).  If the flat form compiles the
// same hazard on BOTH binaries the class is pre-existing (bd 1m5p / bd s82e) and
// the composition only adds customers; if the flat form declines, the rolled
// accept is the composition's own.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0, b1, b2;
    if ((p >> 0) & 1) cq_phi(0.2);
    b0 = cq_theta(b0, 0.5);  if (b0) a -= 3;
    if ((p >> 1) & 1) cq_phi(0.2);
    b1 = cq_theta(b1, 0.5);  if (b1) a -= 3;
    if ((p >> 2) & 1) cq_phi(0.2);
    b2 = cq_theta(b2, 0.5);  if (b2) a -= 3;
    a = cq_theta(a, 0.7);
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
