/* item 3 — the select's merge block also carries a THIRD region's br.
   source order: prep ; select(b1) ; phase region on `a`. */
#include "CQ.h"
#include <math.h>
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;
    if (a == 2) { cq_phi(0.3); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
