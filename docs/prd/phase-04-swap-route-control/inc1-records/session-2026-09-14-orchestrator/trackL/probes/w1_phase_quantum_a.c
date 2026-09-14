/* w1_phase_quantum_a.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Wall-peel: the clobber removed by making the arm a PHASE arm over a quantum `a`. Next wall = `condition predates a non-diagonal gate`, anchored on `%4 = icmp sgt i32 %1, 2` — the LICM-HOISTED loop-invariant compare (row W, bd drbq.12; CLAUDE.md P4's unbounded cross-block gap).
   ⚠ RETIREMENT TRIGGER (L8): when the invariant-compare window becomes per-activation (drbq.12) this accepts; it is the COMPARE-side half of bd wx8g. */
#include "CQ.h"
int main(void) {
    int a = cq_theta(5, 0.1);
    bool b = cq_theta((bool)0, 0.0);
    for (int i = 0; i < 3; ++i) {
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) cq_phi(0.3);
    }
    return cq_measure(a) + cq_measure(b);
}
