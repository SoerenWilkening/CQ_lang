/* t_loop_phase.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Theta-seeded phase spelling. NOTE: declines `cq_measure_<sfx> operand not recognized; expected a tainted i32 handle` — a PROBE ARTEFACT (`cq_measure(a)` on a never-written classical `a`), the pre-existing classical-measure over-decline filed 2026-09-11. Use w2 instead.
   ⚠ RETIREMENT TRIGGER (L8): none — fix the probe, not the compiler. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b = cq_theta((bool)0, 0.0);
    for (int i = 0; i < 3; ++i) {
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) cq_phi(0.3);
    }
    return cq_measure(a) + cq_measure(b);
}
