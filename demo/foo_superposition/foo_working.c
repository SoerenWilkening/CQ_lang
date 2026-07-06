/* foo_working.c — a compiler-SUPPORTED restructuring of foo.c that lowers, links,
   and runs end-to-end (see README.md for why the faithful foo.c declines).

   Kept from the original: a quantum-tainted argument flows through a helper `foo`,
   gets a phase, and is measured. Changed: `foo` is now a PURE value helper (no
   in-body control) so it lifts cleanly into a reversible Phase-6 clone
   `@__cq_q_foo_1`, and the phase is applied unconditionally (no phase-arm merged
   with a constant). */
#include "CQ.h"

int foo(int b) { return b + b; }   /* pure classical value body -> quantum clone-on-taint */

int main(int argc, char *argv[]) {
    (void) argv;
    int b = argc;
    b = cq_theta(b, 0.5);          /* superposition (Ry) */

    int a = foo(b);                /* Phase-6 specialization: @__cq_q_foo_1 (b+b), Bennett-wrapped */
    a = cq_phi(a, 3.14);           /* phase (Rz) on the result */

    return cq_measure(a);          /* measure */
}
