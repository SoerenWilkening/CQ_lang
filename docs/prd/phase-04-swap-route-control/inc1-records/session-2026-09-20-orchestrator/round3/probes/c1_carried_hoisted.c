// C1 — THE COMPOSITION: a bd `zujr` LOOP-CARRIED HANDLE VARIABLE whose per-trip
// arm chain reads a LICM-HOISTED loop-invariant out-of-place TEMPLATE RAIL
// (bd `tu9q` clause (ii-d)'s subject), with a TRAILING NON-DIAGONAL gate on the
// register that rail copies, then a measure.
//   * zujr alone: the body is refused by railLocalQualifies' "accumulating
//     loop-invariant tainted input" clause (y is outside L and not onRail).
//   * tu9q P0+P3 alone: no carried handle, so clause (i)'s header-phi refusal
//     fires instead.
// Together the two refusals are both retired. Rule-8 question: does the hoisted
// rail (and every per-trip rail) get discharged before cqrt_ry_i32(q, 0.9)?
#include "CQ.h"
int main(void) {
    int q = cq_theta(5, 0.5);
    int y = q & 1;              // loop-invariant; -O1 LICM hoists it to the preheader
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= y;      // carried-handle merge; arm chain reads the hoisted rail
    }
    q = cq_theta(q, 0.9);       // TRAILING NON-DIAGONAL gate on q
    return cq_measure(q) + cq_measure(a);
}
