/* PART A, §8 item 1: can a gate minted by a CONTROL EMITTER land on an owned
   interior template rail and reach the relaxed leg of useCompleteBeforeDischarge?
   A rolled in-loop phase kickback whose CONDITION reads the interior rail `d`,
   inside a TWO-BLOCK marked body.  The emitter mints a flag, a toffoli/rz and an
   `_unc` strip; if any of them writes `d` IN PLACE and is not in `D.Calls`, the
   adjoint fires on one arm.  Expected: every emitter gate touches the FLAG, not
   the rail (a rail root gets a CNOT copy or a diagonal rz, never an X bracket). */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        if ((d & 1) == 1) cq_phi(0.3);
        if (k < lim) s += cq_measure(d & 2);
    }
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
