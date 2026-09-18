// P2 — the rail is minted in the INNER loop's PREHEADER, i.e. inside the OUTER
// body, and read by the inner body.  `anchorForConsumer`'s LOut is then the INNER
// loop, whose exit block REPEATS once per outer trip — the configuration the
// anchor's own comment says §2.9's `blockCanRepeat(At)` must refuse.  If it is
// admitted, one forward gate per OUTER trip pairs with one adjoint per outer trip
// (balanced) — but the (ii-d) grant was made about the INNER loop while the mint
// repeats with the OUTER one.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    bool b0[3];
    int a = 5;
    for (int o = 0; o < 3; o++) {
        int p = q * (o + 3);            // minted in the inner preheader
        for (int i = 0; i < 3; i++) {
            if ((p >> i) & 1) cq_phi(0.2);
        }
        b0[o] = cq_theta(b0[o], 0.5);
        if (b0[o]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
