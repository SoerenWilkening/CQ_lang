/* R2 lead 1c: a region whose ARM theta was normalized, with a cq_invert escape
   on the merged value. Region emission + escape composition. */
#include "CQ.h"
int cq_invert_i1(int);
int main(void) {
    int a = 5;
    bool b;                     /* uninitialized -> undef seed */
    if (a >= 3) { b = cq_theta(b, 0.5); }
    return cq_invert_i1(b);
}
