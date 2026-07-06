/* foo_spec_caller.c — the CQ translation unit. `foo` is only DECLARED here, so at -O1
   clang cannot inline it before the cq-lowering pass runs (Rule 9); the pass then sees a
   visible pure callee receiving a QUANTUM argument and lifts it into a reversible clone
   `@__cq_q_foo_1` (Phase-6 specialization / clone-on-taint). This is what happens to a
   plain C function when you hand it a superposition. */
#include "CQ.h"
int foo(int b);                     /* declared, not defined -> not inlinable pre-opt */

int main(int argc, char *argv[]) {
    (void) argv;
    int b = argc;
    b = cq_theta(b, 0.5);           /* superposition (Ry) */
    int a = foo(b);                 /* -> @__cq_q_foo_1(b): reversible clone of b+b */
    a = cq_phi(a, 3.14);            /* phase (Rz) */
    return cq_measure(a);           /* measure */
}
