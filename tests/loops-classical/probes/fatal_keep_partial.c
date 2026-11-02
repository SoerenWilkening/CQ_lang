#include "CQ.h"
/* tests/loops-classical fatal probe (cq-djnk, review loopscl-h2 p31): one bubble pass over four slot cells, then
 * a[3] alone is measured. Only the final rail of a[3] is measured; the other instances the loop stores (a[0..2],
 * and a[i + 1] overwritten by the next trip) are garbage that rules 5, 6 and 14 case 1 clean. Keeping every rail
 * stored into the object (as before) leaked 6 entangled rails; the per-trip keep of the measured cell's final rail
 * is not built: cq::unimplemented. */
unsigned p31(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned a[4] = {x & 3, (x >> 2) & 3, (x >> 4) & 3, (x >> 6) & 3};
    for (int i = 0; i < 3; i++)
        if (a[i] > a[i + 1]) { unsigned t = a[i]; a[i] = a[i + 1]; a[i + 1] = t; }
    return cq_measure(a[3]) | cq_measure(x) << 8;
}
