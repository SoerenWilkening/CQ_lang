/* slice_control_phase_bool_carried_theta_first_unrolled.c — the HAND-UNROLLED
   twin (K=3) of slice_control_phase_bool_carried_theta_first.c. Its golden must
   be byte-identical to the rolled one's (ctest
   e2e-phase-bool-carried-theta-first-twin-identical); that equality is the only
   instrument that can witness a gate emitted the wrong number of times or in the
   wrong block by the in-loop rail collapse. STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    cq_theta(&b, 0.2); if (b) cq_phi(0.7);
    cq_theta(&b, 0.2); if (b) cq_phi(0.7);
    cq_theta(&b, 0.2); if (b) cq_phi(0.7);
    return cq_measure(b);
}
