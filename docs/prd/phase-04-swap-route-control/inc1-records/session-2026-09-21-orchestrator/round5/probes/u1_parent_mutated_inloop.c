// U1 — THE EXIT-ANCHORED ADJOINT READS THE RAIL'S PARENT.  tu9q P2 moves the
// discharge of a hoisted rail from "just after its last use" to the LOOP EXIT.
// The emitted adjoint is `cq_template_mul_i32_hl_unc(h_p, h_q, 3)` -- it names the
// PARENT `h_q`.  If `q` is RELABELLED inside the loop (M-C in-place `q ^= 1`), the
// adjoint at the exit is computed against a DIFFERENT parent state than the forward
// gate was, so `h_p` does NOT return to |0> -- and it is then FREED, which Rule 6
// says is a hidden measurement collapsing `q`.  Verify-clean, links, runs.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int r = cq_theta(u, 0.3);
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        r = cq_theta(r, 0.1);
        q = q ^ 1;
    }
    return cq_measure(q) + cq_measure(r);
}
int main(void) { return slice(4); }
