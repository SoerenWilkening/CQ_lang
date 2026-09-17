/* c2b — the `int` (i32) TWIN of c2.  No retype is owed at i32, so if this also
 * aborts on the ORACLE the abort class is PRE-EXISTING and bd 11qv only widens
 * its population; if it does NOT, the abort is this increment's. */
#include "CQ.h"
extern void cqrt_probe_sink(int);
int main(void) {
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    cqrt_probe_sink(a);
    return (int)cq_measure(a);
}
