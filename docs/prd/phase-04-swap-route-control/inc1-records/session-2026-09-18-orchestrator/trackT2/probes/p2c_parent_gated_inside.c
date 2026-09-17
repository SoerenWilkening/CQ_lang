/* bd `tu9q` P2, the CLAUSE-(d) boundary (SCOPE_T2 §5 F3).  `a1_apost` with the
   hoisted chain's BORROWED PARENT `a` mutated INSIDE the loop, so no exit
   placement can be sound: the `_unc` at the exit would read a post-Ry basis that
   the forward `sqrt` never saw.  Expected: the component LEAKS — clause (d)
   refuses, and it must refuse the COMPONENT and not the function. */
#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0; int r = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    for (int i = 0; i < 2; ++i) {
        if (sqrt(a + 3.) <= (double)off) { r = cq_theta(r, 0.9); }
        a = cq_theta(a, 0.5);                 /* the borrowed parent, gated inside */
    }
    a = cq_theta(a, 0.7);
    return cq_measure(a) + cq_measure(r);
}
int main(void){(void)slice();return 0;}
