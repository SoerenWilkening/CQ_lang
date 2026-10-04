/* slice_control_phase_bool_eq.c — bd 3qlq.4: `if (b == c) cq_phi(θ)` on two
   `_Bool`s. clang -O1 spells it `xor i1 %b, %c` with the arm on the FALSE
   successor: an XOR node over two rail leaves (`cnot(b,g); cnot(c,g)`), the arm
   fires on g == 0 — and g is an ANCILLA the region minted, so THERE the
   `cqrt_x` bracket is the right form; the two registers still receive no gate.
   STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    bool c = (bool)0; cq_theta(&c, 0.3);
    if (b == c) cq_phi(0.9);
    return cq_measure(b) + cq_measure(c);
}
