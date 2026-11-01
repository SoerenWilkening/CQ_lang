/* tests/calls probe (cq-dxii, review w2a-qram-h1/t8): a classical loop storing into a QRAM object is not walked inline as pure classical
 * (it recorded one store for every trip: the bus was dirty at qram_free); it reaches loops-classical.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec qram_loop_stack.c -o qram_loop_stack.O1.ll */
#include "CQ.h"
int t8(unsigned x0, double t, int c) {
    unsigned x = x0;
    cq_theta(&x, t);
    int a[4];
    for (int j = 0; j < 4; j++) a[j] = j * 7 + 1;
    a[x & 3] = c;
    return cq_measure(a[(x + 1) & 3]);
}
