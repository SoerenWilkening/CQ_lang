/* tests/calls probe (cq-5xde): as depth_other_formal with a classical bounded n
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec depth_classical_formal.c -o depth_classical_formal.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static int f(int n, int m, int a) { if (m <= 0) return a + n; return a - f(n - 1, m - 1, a + 1); }
int r13(int c, int m0, int a) { int m = m0; cq_theta(&m, 1.0); return cq_measure(f(c & 1, m & 3, a)); }
