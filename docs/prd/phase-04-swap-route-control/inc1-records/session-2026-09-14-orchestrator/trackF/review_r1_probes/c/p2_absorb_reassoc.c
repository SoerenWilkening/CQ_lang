#include "CQ.h"
/* p2 — the ABSORPTION attack.  The author rotates `w`, a register available at
   the arm and OFF the condition's backward wire, pinned to the seed (0) on the
   guard's true edge.  `w`'s only surviving use is an expression that ALSO reads
   the region's merge phi, inviting -O1 to reassociate `w` away into a
   phi-descendant.  If it works, F2's genuine witness is gone and only a
   phi-descendant remains. */
int main(void) {
    int q = cq_theta(0, 0.3);
    int w = q + 7;                 /* w == 0 exactly when q == -7 */
    int r = 0;
    if (q == -7) {                 /* on the TRUE edge w is provably 0 = seed */
        r = cq_theta(w, 0.5);      /* RIVAL spelling: in-place Ry on w's rail */
    }
    int z = r + w;                 /* uses M and w together */
    return cq_measure(z) + cq_measure(q);
}
