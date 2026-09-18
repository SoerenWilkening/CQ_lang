// U4 — U1/U2 with a mutation `-O1` CANNOT close-form (xor by the loop index) and a
// trip count too large to unroll, so the parent `q` really is relabelled once per
// trip while the hoisted rail `p = q*3` is discharged ONCE at the loop exit against
// `q`'s FINAL state.  This is the shape U1 and U2 were aiming at and missed:
// `q ^= 1` x3 folded to one xor and `q += 1` x3 became the closed form `q + 3`
// AFTER the loop (CLAUDE.md Rule 9's affine add-recurrence rewrite) -- in both the
// parent was never touched inside the body.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int r = cq_theta(u, 0.3);
    for (int i = 0; i < 1000; i++) {
        if ((p >> (i & 31)) & 1) cq_phi(0.2);
        r = cq_theta(r, 0.1);
        q = q ^ i;
    }
    return cq_measure(q) + cq_measure(r);
}
int main(void) { return slice(4); }
