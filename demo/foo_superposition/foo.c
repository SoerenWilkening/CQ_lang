/* foo.c — CQ demo: a quantum-tainted argument flows through a helper with
   in-body control, then a conditional phase, then a measurement.

   Adjusted from the plain-C original to the CQ intrinsic surface:
     theta(x, a)   -> cq_theta(x, a)   (Ry — the SOLE taint source: makes x quantum)
     phi(x, a)     -> cq_phi(x, a)     (Rz — a phase; propagates taint, never creates it)
     measure(x)    -> cq_measure(x)    (the taint sink)
   `argc` seeds the theta so `b` is a runtime (non-constant) value clang cannot fold. */
#include "CQ.h"

int foo(int b) {
    int a = 0;
    if (b < 5) a += b;
    return a;
}

int main(int argc, char *argv[]) {
    (void) argv;
    int b = argc;
    b = cq_theta(b, 0.5);          /* creates superposition */

    int a = foo(b);
    if (a != 0) a = cq_phi(a, 3.14);

    return cq_measure(a);
}
