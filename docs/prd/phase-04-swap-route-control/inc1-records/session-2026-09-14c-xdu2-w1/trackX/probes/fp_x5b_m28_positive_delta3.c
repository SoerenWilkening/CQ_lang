#include "CQ.h"
/* m28 with the THIRD region's polarity flipped, so b1 is prepared on the
   b0==1 branch and |b0=1,b1=1> has NON-ZERO amplitude.  m28 itself prepares b1
   on the NEGATED branch, so its fourth region (the one the F x P composition
   newly enables) acts on a ZERO-amplitude subspace. */
int main(void) {
    int a = 5;
    bool b0 = 0;
    bool b1 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a < 3){ b1 = cq_theta(b1, 0.5); }
    if (b1 && b0) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
