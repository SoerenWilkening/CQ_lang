/* R2-B — ONE loop carrying BOTH a clause-(b') grant (the loop-CARRIED rail `r`
   under the loop-invariant `_Bool` b) and a clause-(c) grant (the
   iteration-local `w` under the per-trip `_Bool` t).  This is the ONLY shape in
   which `AskedEscape`/`AskedMarking` can differ for one header, i.e. the only
   shape the TWO-SET split exists for.  `r` is measured INSIDE the body so (c3)
   can pass. */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        if (b) r = cq_theta(r, 0.3);              /* (b') — carried */
        bool t = cq_theta((bool)0, 0.4);
        int  w = cq_theta(3, 0.15);
        if (t) w = cq_theta(w, 0.2);              /* (c)  — iteration-local */
        s += cq_measure(r) + cq_measure(w) + cq_measure(t);
    }
    return s;
}
int main(void) { return slice(); }
