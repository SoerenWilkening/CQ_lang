/* R2-I2 (H-1) — a clause-(c) loop whose SECOND tainted branch exists only at
   ROUND 2, built on the shipped two-TU 6.5 recipe: `ext_f` is DECLARED const
   here and DEFINED in w2i2_lib.c, so `-O1` cannot fold it and `%out` is
   data-untainted at round 1.  The in-loop `if ((y>>1)&1)` is therefore a
   CLASSICAL branch when `classifyArms` grants clause (c), and a TAINTED region
   claimed by `detectAndLowerOnwardControl` afterwards. */
#include "CQ.h"
int ext_f(int a);
int slice(void) {
    int q = cq_theta(3, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);           /* R1: 6.5 classical-call arm -> %out    */
    int s = 0;
    for (int k = 0; k < 2; ++k) {      /* clause-(c) loop, granted at round 1   */
        int  r = cq_theta(7, 0.25);
        bool t = cq_theta((bool)0, 0.4);
        if (t) r = cq_theta(r, 0.2);
        if (y > 50) cq_phi(0.3);       /* R2: onward tainted phase, ROUND 2     */
        s += cq_measure(r) + cq_measure(t);
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
