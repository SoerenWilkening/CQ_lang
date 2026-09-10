/* slice_control_phase_bool_int_twin.c — bd 3qlq.4: the `int` spelling of
   slice_control_phase_bool_diamond.c, byte-for-byte except the register type.
   It compiled BEFORE this increment (the ordinary compare flag mint) and is
   committed as the REDUCTION twin of the bool golden — see the bool file's
   header for the three-line reduction. STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    int a = 5;
    int b0 = 0;
    if (a >= 3) {
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) a -= 3;
    if (a >= 3) {
        cq_phi(0.5);
    }
    return cq_measure(b0);
}
