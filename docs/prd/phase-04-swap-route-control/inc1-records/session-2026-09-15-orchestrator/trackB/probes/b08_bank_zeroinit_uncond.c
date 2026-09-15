/* b08 — b07 with the bank EXPLICITLY zero-initialised: the D1 byte-identity
   TWIN of b07 (R2). The two streams must be byte-identical or D1 returns to
   the owner. */
#include "CQ.h"
int main(void) {
    bool b0[3] = {0};
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]);
}
