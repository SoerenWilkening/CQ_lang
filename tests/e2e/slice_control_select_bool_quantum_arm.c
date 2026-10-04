/* slice_control_select_bool_quantum_arm.c — bd test_C_libtooling-r9e5 (Inc
   1b-B.1): `slice_control_select.c`'s canonical 4.4 shape with the compare
   replaced by a bare `_Bool` register — `b ? q : 9`, one QUANTUM operand and one
   CLASSICAL one.

   The quantum operand `q` is already a handle, so `materializeCopySource` is the
   identity on it and no alloc appears; the classical 9 is materialized by
   `cqrt_alloc_i32(9)`. A CNOT-copy of a basis LABEL is correct here precisely
   because both operands are basis-valued (Rule 7 / §16.7 — a coherent operand
   DECLINES, it does not lower), and the same is true of the condition: the copy
   flag reads `b`'s basis label and nothing else.

   EXACTLY ONE free (the copy flag). `q`, `%out` and the materialized scratch are
   LEFT ALLOCATED — freeing an operand entangled with %out through the copy is a
   hidden measurement (Rules 6/8, bd memory
   [select-merge-no-chainwalk-exemption]). STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    int q = 3;
    bool b = 0;
    cq_theta(&q, 0.3);
    cq_theta(&b, 0.5);
    int s = b ? q : 9;
    return cq_measure(s) + cq_measure(b);
}
