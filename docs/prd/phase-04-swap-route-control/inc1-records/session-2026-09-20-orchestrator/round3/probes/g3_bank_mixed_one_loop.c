// G3 — (L3) trigger, ONE loop: the bank cell is WRITTEN with a template-minted
// rail and READ in the same body, beside the carried handle. This is the shape
// where the (L3) store exemption and the (ii-d) root admission meet in one
// iteration.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    bool b[3];
    int a = 5;
    for (int i = 0; i < 3; i++) {
        b[i] = (p >> i) & 1;
        if (b[i]) cq_phi(0.2);
        if (a >= 3) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
