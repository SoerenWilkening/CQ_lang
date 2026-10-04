/* slice_control_select_bool_loop_unrolled.c — bd test_C_libtooling-r9e5 (Inc
   1b-B.1): the HAND-UNROLLED twin of slice_control_select_bool_loop.c. The two
   goldens must be byte-identical (`e2e-select-bool-loop-twin-identical`); see
   that file's header for what the gate does and does not prove. STRICT stage
   2b. */
#include "CQ.h"

int main(void) {
    bool b = 0;
    cq_theta(&b, 0.5);
    int acc = 0;
    { int a = b ? 2 + 0 : 5; acc += cq_measure(a); }
    { int a = b ? 2 + 1 : 5; acc += cq_measure(a); }
    { int a = b ? 2 + 2 : 5; acc += cq_measure(a); }
    return acc + cq_measure(b);
}
