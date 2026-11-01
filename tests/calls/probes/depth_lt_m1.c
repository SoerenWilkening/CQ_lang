/* tests/calls probe (cq-5xde): base case n < -1: the guard admits n == 0, no proof
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec depth_lt_m1.c -o depth_lt_m1.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static int f(int n, int a) { if (n < -1) return a; return a - f(n - 1, a + 1); }
int r15(int n0, int a) { int n = n0; cq_theta(&n, 1.0); return cq_measure(f(n & 1, a)); }
