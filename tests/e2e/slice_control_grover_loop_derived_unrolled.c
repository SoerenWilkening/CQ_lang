/* slice_control_grover_loop_derived_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_grover_loop_derived.c (bd test_C_libtooling-8h7d.5).

   Same body, twice, no loop. Its golden is the reference the rolled form is
   byte-diffed against (ctest entry e2e-grover-loop-derived-twin-identical). This
   straight-line shape is the one bd 160a (M-B Increment 6) cleared: two
   independent derived-condition chains, i.e. two interior COMPONENTS, each
   discharged between its own flag strip and flag free. The loop form has to
   reproduce it from ONE copy of the stream. */

#include <math.h>

#define CQ_GROVER_DERIVED_ITER                     \
    if (sqrt(a + 3.) <= 3.5) {                     \
        a = cq_phi(a, M_PI);                       \
    }                                              \
    a = cq_theta(a, -0.5);                         \
    if (a == 0) {                                  \
        a = cq_phi(a, M_PI);                       \
    }                                              \
    a = cq_theta(a, 0.5);

int slice(void) {
    int a = 0;

    a = cq_theta(a, 0.5);

    CQ_GROVER_DERIVED_ITER
    CQ_GROVER_DERIVED_ITER

    return cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
