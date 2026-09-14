/* R2 lead 1: cq_invert_* escape over an UNCONTROLLED normalized prep.
   The escape makes FreePoint mark the rail Escaped: no reverse-play, no free.
   Question: does normalizing the seed change what escapes / what is emitted? */
#include "CQ.h"
int cq_invert_i32(int);
int main(void) {
    int s;                     /* uninitialized -> undef seed */
    int q = cq_theta(s, 0.5);
    int r = q + 3;
    return cq_invert_i32(r);
}
