/* R2-B' — w2b with a DERIVED per-trip chain added to the body, so the loop has
   something for the SPINE to discharge (the leak signature) AND both grant
   clauses.  If the mixed loop is granted and the marking is refused, conjunct 2
   must fire. */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        if (b) r = cq_theta(r, 0.3);              /* (b') — carried */
        int  u = cq_theta(5, 0.5);
        int  w = cq_theta(3, 0.15);
        if ((u >> 1) & 1) w = cq_theta(w, 0.2);   /* (c)  — derived cond */
        s += cq_measure(r) + cq_measure(w) + cq_measure(u);
    }
    return s;
}
int main(void) { return slice(); }
