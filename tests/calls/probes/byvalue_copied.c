/* cq-c09h (gate 2a unc-h3 p3; owner 2026-11-02: a by-value formal is a copy): the clone's cq_theta on its by-value
 * formal v rotates a copy of the caller's x (copy_i32, then Ry on the copy); x itself is untouched by the call.
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec byvalue_copied.c -o byvalue_copied.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static void rotv(int v, double t) { cq_theta(&v, t); }
int p3(int a, double t1, double t2) {
    int x = a;
    cq_theta(&x, t1);
    int g = (x & 3) + 1;
    rotv(x, t2);
    if (g == 2) cq_phi(1.0);
    return cq_measure(x);
}
