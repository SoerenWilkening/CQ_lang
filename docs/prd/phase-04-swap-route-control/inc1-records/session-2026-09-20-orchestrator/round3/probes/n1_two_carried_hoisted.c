// N1 — TWO carried handles in one body plus the hoisted (ii-d) rail. The
// promotion mints one preheader `cqrt_alloc` per proven phi; two of them beside a
// marked body is the shape where a per-trip discharge could pick the wrong owner.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    int c = 9;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
        if (b0[i]) c -= 2;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a) + cq_measure(c);
}
int main(void) { return slice(4); }
