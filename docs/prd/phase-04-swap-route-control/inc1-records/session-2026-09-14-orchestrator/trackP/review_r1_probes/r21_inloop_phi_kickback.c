#include "CQ.h"
/* the phi kickback INSIDE a bounded loop with the prep OUTSIDE it.  The select
   twin is a shipped fixture (control_swap_accept_select_mergephi_inloop_outside_prep);
   the KICKBACK twin has no fixture. */
int main(void) {
    bool b0 = cq_theta((bool)0, 0.5);
    bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    for (int i = 0; i < 3; ++i) {
        if (b1) cq_phi(0.3);
    }
    return cq_measure(b0) + cq_measure(b1);
}
