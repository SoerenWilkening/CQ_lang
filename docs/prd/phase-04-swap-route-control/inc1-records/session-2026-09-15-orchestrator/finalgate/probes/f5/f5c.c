/* F-5 probe c: a bank cell read through a CONDITIONAL pointer.
   Tests whether getUnderlyingObject (railBankOfPointer) can be defeated, which
   would make the load neither TAINTED nor ALLOW-LIST-CHECKED -> branch (1). */
#include "CQ.h"
int slice(int k) {
    bool b0[3];
    bool c0[3];
    int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) c0[i] = cq_theta(c0[i], 0.25);
    bool *p = k ? b0 : c0;      /* pointer phi across two banks */
    s += cq_measure(p[0]);
    return s;
}
int main(void) { return slice(1); }
