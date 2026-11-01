/* tests/calls probe (cq-5xde): base case n < 0: the level-B call still runs, no depth proof, so the cut is unimplemented (was a silent |0>)
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec depth_lt0.c -o depth_lt0.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static int chain(int n, int a) {
    if (n < 0) return a;
    return a - chain(n - 1, a + 1);
}
int r1(int n0, int a) {
    int n = n0; cq_theta(&n, 0.5);
    return cq_measure(chain(n & 3, a));
}
