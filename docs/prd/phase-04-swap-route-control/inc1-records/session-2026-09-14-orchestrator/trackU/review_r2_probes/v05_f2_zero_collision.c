/* R2 lead 4: can the NORMALIZED ZERO seed collide with a live value under F2?
   The condition register `g` is provably 0 on the true edge of `if (!g)`, and
   the normalized seed is exactly `i1 0`.  The record claims the rule can only
   ever produce a FRESH prep.  Attack that. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool g = 0;
    if (a >= 3) { g = cq_theta(g, 0.5); }
    bool b;                     /* uninitialized -> seed normalized to i1 0 */
    if (!g) { b = cq_theta(b, 0.25); }
    return cq_measure(b) + cq_measure(g);
}
