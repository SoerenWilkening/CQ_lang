/* u2's shape, but the SEED is a DIFFERENT uninitialized object from the merge's
   straight-through incoming. -O1 spells both `undef`. If this lowers identically
   to u2, the source comment's "ONE OBJECT, READ TWICE" is a C-level story the IR
   cannot carry -- the rule is really "any undef seed + any undef incoming of a
   phi that carries it". */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b0 = 0;
    bool b1;   /* object B -- the merge's straight-through incoming */
    bool x;    /* object A -- the SEED */
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0) a -= 3;
    if (a >= 3){ b1 = cq_theta(x, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
