/* bd `tu9q` P2, the MULTI-EXIT boundary (SCOPE_T2 §5 F2).  `a1_apost` with a
   second, CLASSICAL exit out of the loop, so `Loop::getUniqueExitBlock()` is null
   and `loopExitDischargePoint` returns nullptr.  Expected: today's behaviour
   exactly — the hoisted `sqrt` chain is LEFT ALLOCATED (Rule 6), never freed at a
   point that repeats. */
#include <math.h>
volatile int off = 3;
volatile int esc = 9;
int slice(void){
    int a = 0; int r = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    for (int i = 0; i < 2; ++i) {
        if (esc == 7) return cq_measure(r);      /* a SECOND exit block */
        if (sqrt(a + 3.) <= (double)off) { r = cq_theta(r, 0.9); }
    }
    a = cq_theta(a, 0.7);
    return cq_measure(a) + cq_measure(r);
}
int main(void){(void)slice();return 0;}
