/* tests/calls probe (cq-5xde): base case n <= 0: depth proved per chain (n & 3 and n & 1 cut at levels 3 and 1); §6 against the C program
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec depth_le0.c -o depth_le0.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static int chain(int n, int a) {
    if (n <= 0) return a;
    return a - chain(n - 1, a + 1);
}
int r4(int n0, int a) {
    int n = n0; cq_theta(&n, 0.5);
    return cq_measure(chain(n & 3, a) + chain(n & 1, a + 7));
}
