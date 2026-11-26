/* tests/loops-classical probe (cq-0u5ti, CR rules 8, 9, 14 case 3; tinycc _tcc_backtrace): in a case-3 trip, a case-3
 * sub-loop with a quantum exit at its header and a classical one at its latch into an exit arm (L8) that keeps nothing (the
 * arm stays per trip). The arm is also entered from the outer header by a quantum edge only, so the sub-loop's unit ends in
 * the open flow, which runs the arm on the outside paths: else the latch has no back edge. Regenerate c3_tail.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec c3_tail.c -o c3_tail.O1.ll */
#include "CQ.h"
int ct_skip(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 1, j, k = 0;
  do {
    if ((x >> i) & 1) goto L8;
    j = i;
    while ((x >> (j + 1)) & 1) {
      j--;
      if (j == 0) goto L8;
    }
    goto L9;
  L8:
    k += i;
  L9:
    i++;
  } while (i != 8 && !(x & 0x100));
  return cq_measure(i + k);
}
