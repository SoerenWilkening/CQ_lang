/* THE CAPABILITY, as a twin row (owner constraint relayed 2026-09-15): a
   DISTINCT THETA PER CELL, minted INSIDE the walk loop.  Both halves ACCEPT and
   the streams are byte-identical — the shipped `e2e-railbank-flat-twin-identical`
   property, carried here so the decline gate and the identity gate cannot drift
   apart. */
#include "CQ.h"
int slice(void) {
    bool b0[3]; int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
int main(void) { (void) slice(); return 0; }
