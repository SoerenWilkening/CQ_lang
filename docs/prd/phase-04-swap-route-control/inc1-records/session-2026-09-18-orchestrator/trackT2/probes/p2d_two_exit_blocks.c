/* bd `tu9q` P2, the MULTI-EXIT boundary, second attempt: the extra exit is placed
   AFTER the region (so it does not trip the 2c condition-wire fence the way
   `p2b` does) and lands in a DIFFERENT block from the normal exit, so
   `Loop::getUniqueExitBlock()` is null.  Expected: the hoisted `sqrt` chain is
   LEFT ALLOCATED — today's behaviour, and the safe direction (Rule 6). */
#include <math.h>
volatile int off = 3;
volatile int esc = 9;
int slice(void){
    int a = 0; int r = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    for (int i = 0; i < 2; ++i) {
        if (sqrt(a + 3.) <= (double)off) { r = cq_theta(r, 0.9); }
        if (esc == 7) goto other;            /* a SECOND exit BLOCK */
    }
    a = cq_theta(a, 0.7);
    return cq_measure(a) + cq_measure(r);
other:
    return cq_measure(r);
}
int main(void){(void)slice();return 0;}
