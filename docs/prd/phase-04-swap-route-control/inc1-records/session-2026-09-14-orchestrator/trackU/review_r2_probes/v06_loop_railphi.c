/* R2: the loop layer.  bd L-3 records that `bool b = 0` gives railPhiRootMint
   NO MINT, i.e. a CONSTANT-ZERO header incoming and an UNDEF header incoming
   are not the same input to the rolled in-loop collapse.  The normalizer turns
   the second into the first. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b;                     /* uninitialized -> undef, normalized to 0 */
    for (int i = 0; i < 3; ++i) {
        if (a >= 3) { b = cq_theta(b, 0.5); }
    }
    return cq_measure(b) + cq_measure(a);
}
