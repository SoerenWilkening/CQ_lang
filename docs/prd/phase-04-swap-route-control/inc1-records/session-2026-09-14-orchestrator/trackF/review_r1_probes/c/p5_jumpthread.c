#include "CQ.h"
/* p5 — JUMP THREADING.  The merge block's own branch reads the region's merge
   phi, which is the classic threading trigger: on the straight-through edge the
   phi is the constant seed, so the later branch is resolvable there.  If JT
   duplicates the merge block into the pred, does any phi descendant end up
   AVAILABLE at a slot? */
int main(void) {
    bool q = cq_theta(0, 0.5);
    bool b1 = 0, b2 = 0;
    int a = 7;
    if (q) { b1 = cq_theta(b1, 0.5); }   /* REGION, merge phi M over b1 */
    if (b1) { a = 1; } else { a = 9; }   /* a is a phi descendant */
    if (a > 3) { b2 = cq_theta(b2, 0.5); }
    return cq_measure(q)+cq_measure(b1)+cq_measure(b2)+cq_measure(a);
}
