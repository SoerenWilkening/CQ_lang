/* Track S — the DISCRIMINATING CONTROL: the same live-register shape but with a
   ROOT-MINT invariant base and an in-loop region, i.e. exactly the D4 Grover
   idiom `invariantRegisterRoots` (3qlq C-1) was built to serve.  Expected to
   DISCHARGE rolled == unrolled. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    for (int k = 1; k <= 2; ++k)
        if ((y >> k) & 1) cq_phi(0.3);
    y = cq_theta(y, 0.9);
    return cq_measure(y);
}
int main(void) { return slice(); }
