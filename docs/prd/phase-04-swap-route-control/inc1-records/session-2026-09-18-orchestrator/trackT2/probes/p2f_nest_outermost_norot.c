/* bd `tu9q` P2, ROUND-2 LENS 5 (the `emkg` class): a rail minted OUTSIDE a NEST
   and read in its INNERMOST body. `anchorForConsumer` walks OUTWARD to the
   OUTERMOST loop that does not contain the mint, so the discharge must land after
   the WHOLE nest — anchoring at the INNER exit would put a once-only discharge on
   a point that repeats once per OUTER trip, which §2.9's
   `blockCanRepeat(At->getParent())` would then refuse as a LEAK rather than as the
   right placement. */
#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0; int r = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    for (int i = 0; i < 2; ++i)
        for (int j = 0; j < 2; ++j)
            if (sqrt(a + 3.) <= (double)off) { r = cq_theta(r, 0.9); }
    /* no post-loop interference: the 2c condition-wire fence claims the
       rotated spelling before P2 is ever reached (measured, p2e) */
    return cq_measure(a) + cq_measure(r);
}
int main(void){(void)slice();return 0;}
