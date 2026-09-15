/* b13 — the D1 / R2 TWIN of b12: the same program with the bank explicitly
   zero-initialised.  Owner ruling D1 admits the uninitialised spelling by C6
   TOTALITY alone; R2 says the byte-identity measurement is owed WITH the
   accept.  This pair is the population. */
#include "CQ.h"
int main(void) {
    bool b0[3] = {0}; int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
