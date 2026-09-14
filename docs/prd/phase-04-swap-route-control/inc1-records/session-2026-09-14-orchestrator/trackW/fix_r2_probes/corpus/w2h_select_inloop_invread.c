/* R2-H1 — an IN-LOOP 4.4 DATA SELECT (not an R7 grant, so NO record and NO
   re-ask) in a body whose marking `markIfRailLocal` refuses, beside a per-trip
   derived chain the spine must discharge.  Does the "record at EVERY grant"
   argument cover the grants R7 does not own? */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  a = cq_theta(7, 0.25);
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(5, 0.5);
        a = b ? a - 3 : a;
        s += cq_measure(((u >> 1) & 1) + (int)b);
    }
    return s + cq_measure(a);
}
int main(void) { return slice(); }
