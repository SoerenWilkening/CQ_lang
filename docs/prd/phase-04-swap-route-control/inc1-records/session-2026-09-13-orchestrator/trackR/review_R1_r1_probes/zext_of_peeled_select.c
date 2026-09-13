/* ITEM 5: the clone's SELECT (not the clone) zero-extended and pinned against an
   i32 seed.  The peel manufactures a clone of `b0 == 1` and an i1 mux `u`;
   `(int)u` is pinned to i32 0 on BOTH edges and collides with the prep's seed.
   The zext is not a clone and is not excluded -> must stay a DECLINE. */
#include "CQ.h"
int main(void) {
    int  b0 = cq_theta(0, 0.5);
    bool u = 0;
    int  z = 0;
    if (b0 == 1) { u = (b0 > 7); z = cq_theta(z, 0.5); }
    int zu = (int)u;
    return cq_measure(b0) + cq_measure(z) + zu;
}
