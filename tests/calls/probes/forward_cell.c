/* tests/calls probe (cq-pgen, 109's put): a clone storing a formal's handle unchanged into the caller's cell
 * (TaintInfo::cellForward, T5): no copy-out in the clone, no twin in the caller; the caller's load names its
 * own rail, also in a classically bounded loop. Regenerate: clang -O1 -S -emit-llvm -target
 * x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec forward_cell.c -o forward_cell.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static void put(int *v, int val) { v[0] = val; }
__attribute__((noinline)) static void put2(int *v, int val) { v[0] = val; }
int fwd_once(int x0, double th, int i) {
    int x = x0;
    cq_theta(&x, th);
    int v[1];
    put(v, x + i);
    return cq_measure(v[0] * 3);
}
int fwd_loop(int x0, double th, int n, int m) {
    int x = x0;
    cq_theta(&x, th);
    int acc = 0;
    for (int i = 0; i < m; i++) {
        int v[n];
        put2(v, x ^ i);
        acc -= v[0];
    }
    return cq_measure(acc);
}
