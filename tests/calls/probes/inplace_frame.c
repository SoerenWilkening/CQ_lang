/* tests/calls probe (cq-i9wk, CR rules 18, 19, 20): a function's in-place activation (an entry, or a callee reached
 * with no quantum argument) has its own frame. g's clone stores a handle into its local y through helper's clone;
 * the entry g, called with a classical x, stores a classical value there and is not rewritten (before cq-i9wk one
 * object per alloca site made the entry's y[0] a slot cell, so the entry's helper call read as quantum: musl
 * sin's __rem_pio2(x, y)). h keeps a classical caller of g, so g stays in the output unrewritten. Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0
 * -I ../../../../CQ_spec inplace_frame.c -o inplace_frame.O1.ll */
#include "CQ.h"

__attribute__((noinline)) static int helper(int x, int *out) {
    out[0] = x * 3;
    out[1] = x ^ 5;
    return x + 1;
}

__attribute__((noinline)) int g(int x) {
    int y[2];
    int r = helper(x, y);
    return r + y[0] - y[1];
}

int f(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    return cq_measure(g(x));
}

int h(int x) {
    return g(x) * 2;
}
