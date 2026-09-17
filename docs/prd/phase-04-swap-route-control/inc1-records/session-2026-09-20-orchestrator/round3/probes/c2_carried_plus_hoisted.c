// C2 — THE COMPOSITION, on tu9q's OWN ht_rolled.c skeleton with zujr's carried
// handle substituted for the phase arm.
//   `p = q*3` is the LICM-HOISTED loop-invariant out-of-place TEMPLATE RAIL that
//   bd `tu9q` clause (ii-d) admits as a Root; `a` is the bd `zujr` LOOP-CARRIED
//   HANDLE VARIABLE (a value arm re-mints `%out` every trip).
//   `q = cq_theta(q,0.9)` after the loop is the TRAILING NON-DIAGONAL gate on the
//   register `p` copies — the Rule-8 interference the rolled form must not lose.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int r = cq_theta(u, 0.3);
    int p = q * 3;
    int a = 5;
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) a -= 3;
        r = cq_theta(r, 0.1);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(r) + cq_measure(a);
}
int main(void) { return slice(4); }
