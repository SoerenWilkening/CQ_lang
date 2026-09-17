// M1 — THE MULTIPLICITY SHAPE (ii-d)'s licence does not cover.
//
// `p = q*3` is minted ONCE, before BOTH loops.  Its ONLY users are inside the
// INNER loop body, so (ii-d)'s three conjuncts are all satisfied FOR THE INNER
// LOOP: the mint is outside it, it mints an out-of-place template rail, the inner
// loop has a unique exit block, and every user is inside it.  But the inner
// loop's exit block sits INSIDE THE OUTER LOOP, so P2's loop-exit anchor
// discharges the rail ONCE PER OUTER TRIP against ONE forward gate.
//
// EXPECTED IF THE HAZARD IS REAL: `cq_template_mul_i32_hl` 1x and
// `cq_template_mul_i32_hl_unc` 2x (K_outer), i.e. a DOUBLE UNCOMPUTE of a rail
// that was already returned to |0> and freed -- Rule 8 use-after-free, and the
// second adjoint re-entangles h0 with a freed rail right before cqrt_ry_i32.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int r = cq_theta(u, 0.3);
    for (int o = 0; o < 2; o++) {
        for (int i = 0; i < 2; i++) {
            if ((p >> i) & 1) cq_phi(0.2);
            r = cq_theta(r, 0.1);
        }
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { return slice(4); }
