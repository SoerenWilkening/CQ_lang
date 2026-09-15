/* o03 — the OWNER'S INNER LOOP verbatim (example/grover/grover_oracle_uncompute.c
   lines 83-95 + 129-131, as copied in trackB/probes/b01_owner_verbatim.c).
   DECLINES on every binary at DECISIONS.md E5's wall 3 (`control flow inside a
   loop body under quantum control`), which is bank-INDEPENDENT and belongs to
   `iterationLocalRollable` (c3), not to W1 and not to this fix.  It is here as
   the DEFERRED-CAPABILITY control: the fix must not change its decline, and the
   fix's own analysis must not RECORD a stale reader on it (checked with
   CQ_STALEBANK_DBG, which runs at the ANALYSIS slot ABOVE wall 3). */
#include "CQ.h"
#include <math.h>
int main(void) {
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        if (a >= 3){
            b0[i] = cq_theta(b0[i], 0.5);
        }
        if (b0[i]) a -= 3;
    }
    return cq_measure(b0[0]) + cq_measure(b0[1])  + cq_measure(b0[2]) + cq_measure(a);
}
