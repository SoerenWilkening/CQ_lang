/* foo_noinline.c — foo.c with __attribute__((noinline)) so `foo` survives clang -O1
   as its own function (not inlined into main). This is the un-inlined shape that
   Phase-6 specialization must lift into a reversible quantum clone (issue 5po2). */
#include "CQ.h"

__attribute__((noinline)) int foo(int b) {
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
