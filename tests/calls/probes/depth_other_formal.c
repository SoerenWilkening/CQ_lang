/* tests/calls probe (cq-5xde): the bounded decremented formal n does not control termination; m (proved bound 3) does, taint cuts at level 1
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec depth_other_formal.c -o depth_other_formal.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static int f(int n, int m, int a) { if (m <= 0) return a; return a - f(n - 1, m - 1, a + 1); }
int r14(int m0, int a) { int m = m0; cq_theta(&m, 1.0); return cq_measure(f(1, m & 3, a)); }
