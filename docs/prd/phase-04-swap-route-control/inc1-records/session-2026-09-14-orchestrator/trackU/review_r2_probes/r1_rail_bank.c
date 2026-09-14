/* lead 6 — the rail-bank composition.  Track L records `bool b[N]` uninitialized
   declining at the STORE, before lowerLoops. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b[2];
    for (int i = 0; i < 2; ++i) { if (a >= 3) { b[i] = cq_theta(b[i], 0.5); } }
    return cq_measure(b[0]) + cq_measure(b[1]);
}
